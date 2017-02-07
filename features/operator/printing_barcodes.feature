@javascript
Feature: Printing barcodes
An operator
Should be able to print barcodes in a background task

Background:
Given I have the following users:
| User    | Role             |
| Alice   | administrator    |
| Bob     | operator         |

Given I have the following printers:
| Name      | Printer Type | Default |
| printer1  | Tube         | true    |
| printer2  | Plate        | true    |

Given I have the following label templates:
| Name          | Type  | External Id |
| Tubetemplate  | Tube  | 1           |
| PlateTemplate | Plate | 2           |

Given I have to process these tubes that are on my table:
|  Barcode | Facts                   |
|  1       | is:NotStarted, a:Tube   |
|  2       | is:NotStarted, a:Tube   |

Given we use these activity types:
| Name          |
| Printing barcodes |

Given we use these step types:
| Name                       | Activity types |
| Create a tube              | Printing barcodes  |
| Create a tube rack in SS   | Printing barcodes  |
| Create a plate in SS       | Printing barcodes  |

Given the step type "Create a tube" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :removeFacts {?p :is :NotStarted.}.
  :step :createAsset {?p :a :Tube.}.
}.
"""
Given the step type "Create a tube rack in SS" has this configuration in N3:
"""
{
  ?p :a :Tube .
  ?p :is :NotStarted.
  ?p :maxCardinality """0""".
} => {
  :step :removeFacts {?p :is :NotStarted.}.
  :step :createAsset {?p :a :TubeRack.
  }.
}.
"""

Given I have the following kits in house
| Barcode | Kit type                           | Activity type |
| 1       | Printing tube                      | Printing barcodes |

Given the laboratory has the following instruments:
| Barcode | Name          | Activity types           |
| 1       | My instrument | Printing barcodes            |


Scenario: Printing a barcode
When I use the browser to enter in the application
Then I should see the Instruments page

When I log in as an unknown user
Then I am not logged in

When I log in as "Bob"
Then I am logged in as "Bob"

And I create an activity with instrument "My Instrument" and kit "1"

When I scan these barcodes into the selection basket:
|Barcode |
| 1      |
| 2      |

Then I should see these barcodes in the selection basket:
| Barcode |
| 1       |
| 2       |

When I want to print "2" new barcodes starting from "33" with template "TubeTemplate" at printer "printer1"
And I perform the step "Create a tube"
Then I should have printed what I expected
