# Cucumber & Serenity in parallel
[![pipeline status](https://git.aimprosoft.com/QA/parallel_testing/badges/master/pipeline.svg)](https://git.aimprosoft.com/QA/parallel_testing/commits/master)  [Docs](https://johnfergusonsmart.com/running-parallel-tests-serenity-bdd-cucumber/)
## Background
The [Cucumber JVM Parallel Plugin](https://github.com/temyers/cucumber-jvm-parallel-plugin) works nicely with the Cucumber conventions that Serenity BDD uses. The plugin will look for feature files underneath the `src/test/resources` directory and create runners for each feature. But you will need to tweak your `pom.xml` file a little.

## Configuration
The **Cucumber JVM Parallel Plugin** works with the `maven-failsafe-plugin`, so your Cucumber scenarios will be executed when you run `mvn verify`. 
By default, it generates test runners with the `IT` suffix, so make sure your `maven-failsafe-plugin` configuration will look for files matching this format.

The `maven-failsafe-plugin` is also where you configure your parallel execution. In the code below, we run 1 parallel thread per processor core:

```xml
        ...
    <properties>
        ...
        <count.of.threads>1C</count.of.threads>
        ...
    </properties>
            ...
            <plugin>
                <artifactId>maven-failsafe-plugin</artifactId>
                <version>2.20</version>
                <configuration>
                    <includes>
                        <include>**/*IT.java</include>
                    </includes>
                    <forkCount>${count.of.threads}</forkCount>
                    <reuseForks>true</reuseForks>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>integration-test</goal>
                            <goal>verify</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            ...
```

This will run your feature runner classes in parallel. Next, you need to configure the `cucumber-jvm-parallel-plugin` to generate these runners. 
The configuration will look something like this:

```xml
            ...
            <properties>
                    ...
                    <!-- One of [SCENARIO, FEATURE]. SCENARIO generates one runner per scenario.-->
                    <!-- FEATURE generates a runner per feature.-->
                    <parallel.scheme>FEATURE</parallel.scheme>
                    ...
                </properties>
            ...
            <plugin>
                <groupId>com.github.temyers</groupId>
                <artifactId>cucumber-jvm-parallel-plugin</artifactId>
                <version>4.2.0</version>
                <executions>
                    <execution>
                        <id>generateRunners</id>
                        <phase>generate-test-sources</phase>
                        <goals>
                            <goal>generateRunners</goal>
                        </goals>
                        <configuration>
                            <!-- Mandatory -->
                            <!-- List of package names to scan for glue code. -->
                            <glue>
                                <package>com.aimprosoft.steps</package>
                            </glue>
                            <!-- The directory, which must be in the root of the runtime classpath, containing your feature files.  -->
                            <featuresDirectory>src/test/resources/features/</featuresDirectory>
                            <parallelScheme>${parallel.scheme}</parallelScheme>
                            <!-- Specify a custom template for the generated sources (this is a path relative to the project base directory) -->
                            <customVmTemplate>src/test/resources/cucumber-serenity-runner.vm</customVmTemplate>
                            <!-- The directory, which must be in the root of the runtime classpath, containing your feature files.  -->
                            <featuresDirectory>src/test/resources/features/</featuresDirectory>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            ...
```
There are a bunch of configuration options on the [web site](https://github.com/temyers/cucumber-jvm-parallel-plugin), but the most important are the `parallelScheme` and the `customVmTemplate`.

* The `parallelScheme` should be `FEATURE`. The `SCENARIO` option will generate a test runner for each scenario. This would result in a better distribution of test execution. Unfortunately, each scenario in scenario outlines are also executed in parallel, which messes with Serenity’s reporting. 
* The `glue` package should be the root package where your step definitions are located.
* The default configuration will use the default `JUnit Cucumber runner`. For Serenity, we need to use the `CucumberWithSerenity` class instead. To do this, simply define a custom template to use to generate the test runners. Create a file called `cucumber-serenity-runner.vm` and place it in your `src/test/resources` directory. The file should look like this:

```java
    #parse("/array.java.vm")
    #if ($packageName)
    package $packageName;
    
    #end##
    import org.junit.runner.RunWith;
    
    import cucumber.api.CucumberOptions;
    import net.serenitybdd.cucumber.CucumberWithSerenity;
    
    @RunWith(CucumberWithSerenity.class)
    @CucumberOptions(
    strict = $strict,
    features = {"$featureFile"},
    plugin = #stringArray($plugins),
    monochrome = $monochrome,
    #if(!$featureFile.contains(".feature:") && $tags)
    tags = #stringArray($tags),
    #end
    glue = #stringArray($glue))
    public class $className {
    }
```

## Execution

When you run `mvn verify`, your Cucumber features will be executed in parallel.

For more customization such as number of threads or parallel scheme, you can pass additional arguments into `maven goal`.
The parameter `count.of.threads` defines the maximum number of JVM processes that `maven-failsafe-plugin` will spawn concurrently to execute the tests. 

* `-Dcount.of.threads=1C` will be change default count of threads to:
  
    `1C` -  if you terminate the value with a `'C'`, that value will be multiplied with the number of available CPU cores in your system. 
  For example `count.of.threads=2.5C` on a Quad-Core system will result in forking up to ten concurrent JVM processes that execute tests.  
  
    `2`  -  will be change default count of threads to set value. For example `count.of.threads=4` will result in forking up to four concurrent JVM processes that execute tests.
  
  
* `-Dparallel.scheme=FEATURE` will be change default parallel scheme to:
  
    `SCENARIO` - generates one runner per scenario. Each scenario will be executed in the concurrent JVM process.
 
    `FEATURE` - generates a runner per feature. Each feature will be executed in the concurrent JVM process.
    
## Additional configuration

To speed up the execution time, let's make some additional configuration of Serenity and the default logger.

### Logger
> **Note:**
 Printing on the console requires kernel time, kernel time means the cpu will not be running on user mode which basically means your cpu will be busy executing on kernel code instead of your application code.
 We will reduce the logging time decreasing the logging information.


In the `pom.xml` change the default logger from `slf4j-simple` to `slf4j-log4j12`, it should be like this:

```xml
            <dependency>
                <groupId>org.slf4j</groupId>
                <artifactId>slf4j-log4j12</artifactId>
                <version>1.7.7</version>
            </dependency>
```
Create a file called `log4j.properties` and place it in your `src/test/resources` directory. The file should look like this:

```properties
   ### direct log messages to stdout ###
   log4j.appender.stdout=org.apache.log4j.ConsoleAppender
   log4j.appender.stdout.target=System.out
   log4j.appender.stdout.encoding=UTF-8
   log4j.appender.stdout.layout=org.apache.log4j.EnhancedPatternLayout
   log4j.appender.stdout.layout.ConversionPattern=%d{ABSOLUTE} %t %5p %c{1.}:%L - %m%n
   ### set log levels - for more verbose logging change 'info' to 'debug' ###
   log4j.rootLogger=error, stdout
   log4j.category.net.serenitybdd=warn
```

The loggin information will be shown as example below. The failed tests will write a full stack trace, other tests will be shown with a little information of execution.

```bash
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running Parallel01IT
XXX Created runtime cucumber.runtime.RuntimeOptions@156b88f5
Starting ChromeDriver 2.33.506092 (733a02544d189eeb751fe0d7ddca79a0ee28cce4) on port 9891
Only local connections are allowed.
Nov 27, 2017 11:18:12 AM org.openqa.selenium.remote.ProtocolHandshake createSession
INFO: Detected dialect: OSS

1 Scenarios (1 passed)
3 Steps (3 passed)
0m4.957s

[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.07 s - in Parallel01IT
[INFO] Running Parallel02IT
XXX Created runtime cucumber.runtime.RuntimeOptions@7173ae5b
Nov 27, 2017 11:18:17 AM org.openqa.selenium.remote.ProtocolHandshake createSession
INFO: Detected dialect: OSS
11:18:21,075 main ERROR n.s.c.Serenity:322 - 
           __  _____ _____ ____ _____   _____ _    ___ _     _____ ____  
  _       / / |_   _| ____/ ___|_   _| |  ___/ \  |_ _| |   | ____|  _ \ 
 (_)_____| |    | | |  _| \___ \ | |   | |_ / _ \  | || |   |  _| | | | |
  _|_____| |    | | | |___ ___) || |   |  _/ ___ \ | || |___| |___| |_| |
 (_)     | |    |_| |_____|____/ |_|   |_|/_/   \_\___|_____|_____|____/ 
          \_\                                                            

TEST FAILED WITH ERROR: 1.0001 Looking up the definition
---------------------------------------------------------------------
11:18:21,170 main ERROR n.s.c.Serenity:357 - TEST FAILED AT STEP Should see definition: An edible fruit produced by the pear tree, similar to an apple but elongated towards the stem.
11:18:21,172 main ERROR n.s.c.Serenity:359 - The following error occurred: no such element: Unable to locate element: {"method":"tag name","selector":"ol"}  (Session info: chrome=62.0.3202.94)  (Driver info: chromedriver=2.33.506092 (733a02544d189eeb751fe0d7ddca79a0ee28cce4),platform=Linux 4.4.0-101-generic x86_64) (WARNING: The server did not provide any stacktrace information)Command duration or timeout: 0 millisecondsFor documentation on this error, please visit: http://seleniumhq.org/exceptionso_such_element.htmlBuild info: version: '3.7.1', revision: '8a0099a', time: '2017-11-06T21:01:39.354Z'System info: host: 'SB-107', ip: '127.0.1.1', os.name: 'Linux', os.arch: 'amd64', os.version: '4.4.0-101-generic', java.version: '1.8.0_151'Driver info: org.openqa.selenium.remote.RemoteWebDriverCapabilities {acceptSslCerts: true, applicationCacheEnabled: false, browserConnectionEnabled: false, browserName: chrome, chrome: {chromedriverVersion: 2.33.506092 (733a02544d189e..., userDataDir: /tmp/.org.chromium.Chromium...}, cssSelectorsEnabled: true, databaseEnabled: false, handlesAlerts: true, hasTouchScreen: false, javascriptEnabled: true, locationContextEnabled: true, mobileEmulationEnabled: false, nativeEvents: true, networkConnectionEnabled: false, pageLoadStrategy: normal, platform: LINUX, platformName: LINUX, rotatable: false, setWindowRect: true, takesHeapSnapshot: true, takesScreenshot: true, unexpectedAlertBehaviour: , unhandledPromptBehavior: , version: 62.0.3202.94, webStorageEnabled: true}Session ID: 529296a31341a2bdcaf0dff95f42f8b8*** Element info: {Using=tag name, value=ol}For documentation on this error, please visit: http://seleniumhq.org/exceptionso_such_element.htmlBuild info: version: '3.7.1', revision: '8a0099a', time: '2017-11-06T21:01:39.354Z'System info: host: 'SB-107', ip: '127.0.1.1', os.name: 'Linux', os.arch: 'amd64', os.version: '4.4.0-101-generic', java.version: '1.8.0_151'Driver info: driver.version: unknown
11:18:21,184 main ERROR n.s.c.Serenity:322 - 
    
```

### Serenity properties

> **Note:**
Hard configuration of Serenity properties or using default configuration can make affect on the total execution time.
The properties like: `Explicit/Implicit timeouts`, `screenshots taking` without properly configuring increase the execution time. We will reduce this affects in the way described below. 

Update/Add following properties in the `serenity.properties` file:

```properties
# Customize browser size
serenity.browser.height = 900
serenity.browser.width = 1440

# How long should the driver wait for elements not immediately visible.
serenity.timeout=50

# How long webdriver waits by default when you use a fluent waiting method, in milliseconds.
webdriver.wait.for.timeout=50

#How long webdriver waits for elements to appear by default, in milliseconds.
webdriver.timeouts.implicitlywait=50

# Set this property to provide more detailed logging of WebElementFacade steps when tests are run.
serenity.verbose.steps=true

# Should Thucydides display detailed information in the test result tables.
# If this is set to true, test result tables will display a breakdown of the steps by result. This is false by default.
serenity.reports.show.step.details=true

# During data-driven tests, some browsers (Firefox in particular) may slow down over time due to memory leaks.
# To get around this, you can get Serenity to start a new browser session at regular intervals when it executes data-driven tests.
serenity.restart.browser.frequency=500

# Pause (in ms) between each test step.
thucycides.step.delay=5

#The property serenity.take.screenshots can be set to configure how often the screenshots are taken.
serenity.take.screenshots=FOR_FAILURES
```

> **Note:**
By default, Serenity saves a screenshot for every step executed during the tests. If you really need the screenshots of every step, you should set  `serenity.take.screenshots=FOR_EACH_ACTION`, but it's not recommended. Try to always set this parameter to `FOR_FAILURES` or `DISABLED`

## Integration with CI

### Gitlab CI

Update in the `.gitlab-ci.yml` file your maven goal to 

```yaml
- mvn clean verify -Dcount.of.threads=$PARALLEL_THREADS -Dparallel.scheme=$PARALLEL_SCHEME
```

where `$PARALLEL_THREADS` and `$PARALLEL_SCHEME` variables are preset variables in the file

```yaml
variables:
  PARALLEL_THREADS:         "2"
  PARALLEL_SCHEME:          "SCENARIO"
```
  
For more understandability you can use [`.gitlab-ci.yml`](https://git.aimprosoft.com/QA/parallel_testing/blob/master/.gitlab-ci.yml) template for current project.


### Jenkins CI

For more customization of parallel options during Jenkins execution, let's make some additional changes in the Jenkinsfile:

Add two variables in the top of the pipeline file:

```groovy
def counts = "1\n2\n3\n4\n1C\n1.5C\n2C\n2.5C"
def scheme = "FEATURE\nSCENARIO"
```

Where `counts` is the list of threads number and the `scheme` is the type of parallel scheme (parallel per Scenario/Feature)

In the `parameters` section add two choice parameters, it should look like this:

```groovy
choice(name: 'threads_count', choices: "${counts}", description: 'Number of threads')
choice(name: 'parallel_scheme', choices: "${scheme}", description: 'Parallel scheme')
```

And finally append choice parameters to the maven goal, it should be something like this:

```groovy
sh "/usr/share/maven/bin/mvn ${env.MVN_GOAL} " +
 "-Dcount.of.threads=${params.threads_count} " +
 "-Dparallel.scheme=${params.parallel_scheme}"
```

For more understandability you can use [`Jenkinsfile`](https://git.aimprosoft.com/QA/parallel_testing/blob/master/Jenkinsfile) template for current project.
