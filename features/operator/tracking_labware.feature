@javascript
Feature: Tracking of status of laboratory assets by an operator
In order to keep track of the actual status of the laboratory assets
An operator
Should be able to know past, present and future of any asset while working with it

Background:

Given I am an operator called "Bob"

Given I have to process these tubes that are on my table:
|  Barcode | Facts                   |
|  1       | is:NotStarted, a:Tube   |
|  2       | is:NotStarted, a:Tube   |

Given we use these activity types:
| Name          |
| Tubes to rack |
| Reracking     |

Given we use these step types:
| Name                   | Activity types |
| Upload layout          | Tubes to rack  |
| Change purpose of tube | Tubes to rack  |

Given the step type "Change purpose of tube" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
} => {
  :step :removeFacts {?p :is :NotStarted.}.
  :step :addFacts {?p :is :Started.}.
}.
"""

Given I have the following kits in house
| Barcode | Kit type                           | Activity type |
| 1       | QIAamp Investigator BioRobot       | Tubes to rack |
| 2       | QIAamp Investigator BioRobot       | Tubes to rack |
| 3       | QIAamp Investigator BioRobot       |               |
| 4       | QIAamp 96 DNA QIAcube HT           |               |

Given the laboratory has the following instruments:
| Barcode | Name          | Activity types           |
| 1       | My instrument | Tubes to rack, Reracking |


Scenario: Access to the system as an operator

When I use the browser to enter in the application
Then I should see the Instruments page

When I log in as an unknown user
Then I am not logged in

When I log in as "Bob"
Then I am logged in as "Bob"

Scenario: Create a new activity with some assets

When I create an activity with instrument "My Instrument" and kit "1"
Then I should have created an empty activity for "Tubes to rack"

When I scan these barcodes into the selection basket:
|Barcode |
| 1      |
| 2      |

Then I should see these barcodes in the selection basket:
| Barcode |
| 1       |
| 2       |

Scenario: Process a group of barcodes from the selection basket

When I create an activity with instrument "My Instrument" and kit "1"
And I scan these barcodes into the selection basket:
|Barcode |
| 1      |
| 2      |

Then I should see these barcodes in the selection basket:
| Barcode |
| 1       |
| 2       |

And I should see these steps available:
| Step                    |
| Change purpose of tube  |

When I am not logged in
And I perform the step "Change purpose of tube"
Then I should not have performed the step "Change purpose of tube"

When I log in as "Bob"
Then I am logged in as "Bob"
And I perform the step "Change purpose of tube"
Then I should have performed the step "Change purpose of tube" with the user "Bob"
