// Run this example by adding <%= javascript_pack_tag 'activity' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.

import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

import WebpackerReact from 'webpacker-react'
import Activity from 'components/activity'
import Steps from 'components/step_components/steps'
import StepsFinished from 'components/step_components/steps_finished'
import FactsSvg from 'components/asset_components/facts_svg'
import Facts from 'components/asset_components/facts'
import FactsEditor from 'components/asset_components/facts_editor'
import ReactTooltip from 'react-tooltip'
import ButtonWithLoading from 'components/lib/button_with_loading'
import SearchControl from 'components/lib/search_control'

window.React = React;


WebpackerReact.setup({React,Activity,SearchControl, ButtonWithLoading,Steps,StepsFinished,FactsSvg,Facts,FactsEditor,ReactTooltip})
