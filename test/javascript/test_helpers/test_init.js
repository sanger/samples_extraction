import React, {Fragment} from 'react';
import ReactDOM from 'react-dom';
import $ from 'jquery';
import Adapter from 'enzyme-adapter-react-16';

global.$ = global.jQuery = $;
global.React = React;

configure({ adapter: new Adapter() });

const mockWebsockets = () => {
  global.App = {
    cable: {
      subscriptions: {
        create: jest.fn()
      }
    }
  }
}
