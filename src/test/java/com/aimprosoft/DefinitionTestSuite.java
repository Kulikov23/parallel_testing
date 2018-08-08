package com.aimprosoft;

import cucumber.api.CucumberOptions;
import net.serenitybdd.cucumber.CucumberWithSerenity;
import org.junit.runner.RunWith;

@RunWith(CucumberWithSerenity.class)
@CucumberOptions(features={"src/test/resources/features/1_LookupADefinition.feature",
        "src/test/resources/features/2_LookupADefinition.feature",
        "src/test/resources/features/3_LookupADefinition.feature",
        "src/test/resources/features/4_LookupADefinition.feature"}
)
public class DefinitionTestSuite {}
