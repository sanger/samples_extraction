// Run this example by adding <%= javascript_pack_tag 'activity' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.

import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'


import WebpackerReact from 'webpacker-react'
import Activity from 'components/activity'
window.React = React;
WebpackerReact.setup({React,Activity})

/*import WebpackerReact from 'webpacker-react'
import Turbolinks from 'turbolinks'

Turbolinks.start()

WebpackerReact.setup({Activity})*/
