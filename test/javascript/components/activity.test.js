import React, {Fragment} from 'react';
import ReactDOM from 'react-dom';
import { shallow, mount } from 'enzyme';

import '../test_helpers/test_init'
import {buildActivityState} from "../test_helpers/factories"

import Activity from 'activity';


test('renders Activity component', () => {
  const wrapper = shallow(<Activity {...buildActivityState(0,0)} />);
  expect(wrapper.find('div')).toHaveLength(1);
});

test('renders only one AssetGroupEditor component', () => {
  const wrapper = mount(<Activity {...buildActivityState(2,0)} />);
  expect(wrapper.find('AssetGroupEditor')).toHaveLength(1);
});
