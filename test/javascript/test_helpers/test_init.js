import React, {Fragment} from 'react';
import ReactDOM from 'react-dom';
import $ from 'jquery';
import Adapter from 'enzyme-adapter-react-16';
import { configure } from 'enzyme';

const testInit = () => {
  global.$ = global.jQuery = $;
  global.React = React;

  configure({ adapter: new Adapter() });
  mockWebSockets()
}

const mockWebSockets = () => {
  global.App = {
    cable: {
      subscriptions: {
        create: jest.fn()
      }
    }
  }
}

testInit()
