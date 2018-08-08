Feature: Lookup a definition 4
  In order to talk better
  As an English student
  I want to look up word definitions

  Background: open wikionary
    Given the user is on the Wikionary home page

  Scenario: 4.0001 Looking up the definition of 'apple'
    When the user looks up the definition of the word 'apple'
    Then they should see the definition 'A common, round fruit produced by the tree Malus domestica, cultivated in temperate climates.'

  Scenario: 4.0002 Looking up the definition of 'pear'
    When the user looks up the definition of the word 'pear'
    Then they should see the definition 'An edible fruit produced by the pear tree, similar to an apple but elongated towards the stem.'

  Scenario: 4.0003 Looking up the definition of 'java'
    When the user looks up the definition of the word 'java'
    Then they should see the definition 'A blend of coffee imported from the island of Java.'

  Scenario: 4.0004 Looking up the definition of 'automation'
    When the user looks up the definition of the word 'automation'
    Then they should see the definition 'The act or process of converting the controlling of a machine or device to a more automatic system, such as computer or electronic controls.'

  Scenario: 4.0005 Looking up the definition of 'aim'
    When the user looks up the definition of the word 'aim'
    Then they should see the definition 'The point intended to be hit, or object intended to be attained or affected.'

  Scenario: 4.0006 Looking up the definition of 'parallelism'
    When the user looks up the definition of the word 'parallelism'
    Then they should see the definition 'The state or condition of being parallel; agreement in direction, tendency, or character.'
