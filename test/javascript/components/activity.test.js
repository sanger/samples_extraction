import React from 'react';
import ReactDOM from 'react-dom';
import $ from 'jquery';
global.$ = global.jQuery = $;

import { shallow, configure } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
configure({ adapter: new Adapter() });

import Activity from 'activity';

const testing_props = {
  "activity":{
    "activity_type_name":"My activity",
    "instrument_name":"My instrument",
    "kit_name":"A selected kit",
  },
  "tubePrinter":{
    "optionsData":[
      ["printer 1",1]
    ],
    "defaultValue":8
  },"platePrinter":{
    "optionsData":[
      ["printer 2",2]
    ],
    "defaultValue":2
  },
  "shownComponents":{},
  "activityRunning":false,
  "activityState":null,
  "messages":[]
}

test('renders Activity component', () => {
  global.App = {
    cable: {
      subscriptions: {
        create: jest.fn()
      }
    }
  }

  const wrapper = shallow(<Activity {...testing_props} />);
  expect(wrapper.find('div')).toHaveLength(1);
});
