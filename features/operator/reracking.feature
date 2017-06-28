@javascript
Feature: An operator can rerack labware
In order to optimize resources use
An operator
Can perform Re-racking over plates

Background:

Given I have the following users:
| User    | Role             |
| Alice   | administrator    |
| Bob     | operator         |
| Charles | operator         |

Given we use these activity types:
| Name          |
| Re-racking     |

Given I have the following printers:
| Name      | Printer Type | Default |
| printer1  | Tube         | true    |
| printer2  | Plate        | true    |

Given we use these step types:
| Name                                | Activity types |
| Upload .csv layout for TubeRack     | Re-racking  |
| Create a new empty TubeRack         | Re-racking  |
| Update in Sequencescape             | Re-racking  |

Given the step type "Upload .csv layout for TubeRack" has this configuration in N3:
"""

{
  ?p :a :TubeRack .
  ?p :maxCardinality """1""".
} => {
  :step :stepTemplate """rack_layout_creating_tubes""" .
}.
"""

Given the step type "Upload .csv layout for TubeRack" uses the step template "rack_layout_creating_tubes"

Given the step type "Create a new empty TubeRack" has this configuration in N3:
"""
{
  ?q :maxCardinality """1""".
} => {
  :step :createAsset {
    ?q :a :TubeRack .
    ?q :barcodeType :NoBarcode .
  }.
}.
"""

Given the step type "Update in Sequencescape" has this configuration in N3:
"""
{
  ?p :a :TubeRack .
  ?p :maxCardinality """1""".
} => {
  :step :stepTypeName """Update in Sequencescape""".
  :step :addFacts { ?p :pushTo :Sequencescape . } .
}.
"""

Given I have the following kits in house
| Barcode | Kit type                           | Activity type |
| 1       | Re-racking                          | Re-racking     |

Given the laboratory has the following instruments:
| Barcode | Name          | Activity types  |
| 1       | My instrument | Re-racking       |


Scenario: Modify using the same rack structure several times

When I am a user with name "Charles" and role "Operator"
And I use the browser to enter in the application

Given I want to rerack a tube rack "1" with the following contents:

| Location | Barcode | Sample Id |
| A1       | FR7009  | MGRD92    |
| B1       | FR7010  | MGRD93    |
| C1       | FR7011  | MGRD94    |

And I perform the step "Upload .csv layout for TubeRack"

When I upload the following csv layout:
"""
A01, FR7009
B01, FR7010
C01, FR7011 
"""

Then I should not have send any update message to Sequencescape
When I click on upload
Then I should not have send any update message to Sequencescape
When I click on Finish
Then I should have send an update message to Sequencescape


When I perform the step "Upload .csv layout for TubeRack"
And I upload the following csv layout:
"""
A01, FR7009
B01, FR7010
C01, FR7011 
"""

Then I should not have send any update message to Sequencescape
When I click on upload
Then I should not have send any update message to Sequencescape
When I click on Finish
Then I should have send an update message to Sequencescape

Scenario: Modify a rack using tubes from a different rack

Given I want to rerack a tube rack "2" with the following contents:

| Location | Barcode | Sample Id |
| A1       | FR7012  | MGRD95    |
| B1       | FR7013  | MGRD96    |
| C1       | FR7014  | MGRD97    |

When I perform the step "Upload .csv layout for TubeRack"
And I upload the following csv layout:

| Location | Barcode |
| A1       | FR7009  |
| B1       | FR7010  |
| C1       | FR7011  |
| D1       | FR7012  |
| E1       | FR7013  |
| F1       | FR7014  |

Then I should not have send any update message to Sequencescape
When I click on upload
Then I should not have send any update message to Sequencescape
When I click on Finish
Then I should have send an update message to Sequencescape


