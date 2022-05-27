import React from 'react'
import { shallow, mount } from 'enzyme'

import '../test_helpers/test_init'
import { buildActivityState } from '../test_helpers/factories'

import Activity from 'activity'

describe('Activity', () => {
  it('renders Activity component', () => {
    const wrapper = shallow(<Activity {...buildActivityState(1, 0)} />)
    expect(wrapper.find('div')).toHaveLength(1)
  })

  it('renders only one AssetGroupEditor component', () => {
    const wrapper = mount(<Activity {...buildActivityState(2, 0)} />)
    expect(wrapper.find('AssetGroupEditor')).toHaveLength(1)
  })
})
