Feature: Lookup a definition 1
  In order to talk better
  As an English student
  I want to look up word definitions

  Scenario Outline: 1.0001 Looking up the definition
    Given the user is on the Wikionary home page
    When the user looks up the definition of the word '<word>'
    Then they should see the definition '<result>'
    Examples:
      | word       | result                                                                                                                                       |
      | apple      | A common, round fruit produced by the tree Malus domestica, cultivated in temperate climates.                                                |
      | pear       | An edible fruit produced by the pear tree, similar to an apple but elongated towards the stem.                                               |
      | java       | A blend of coffee imported from the island of Java.                                                                                          |
      | automation | The act or process of converting the controlling of a machine or device to a more automatic system, such as computer or electronic controls. |
      | aim        | The point intended to be hit, or object intended to be attained or affected.                                                                 |

  Scenario: 1.0002 Looking up the definition of 'parallelism'
    Given the user is on the Wikionary home page
    When the user looks up the definition of the word 'parallelism'
    Then they should see the definition 'The state or condition of being parallel; agreement in direction, tendency, or character.'
