import React from 'react'
import { shallow, mount } from 'enzyme'

import '../../test_helpers/test_init'

import { buildAssetGroupData, tubePrinterOptions, platePrinterOptions } from '../../test_helpers/factories'

import AssetGroupPrinting from 'asset_group_components/asset_group_printing'

describe('AssetGroupPrinting', () => {
  const props = (assetCount = 3) => ({
    assetGroup: buildAssetGroupData(1, assetCount),
    platePrinter: platePrinterOptions(),
    tubePrinter: tubePrinterOptions(),
  })

  it('renders a form', () => {
    const wrapper = shallow(<AssetGroupPrinting {...props()} />)
    expect(wrapper.find('FormFor')).toHaveLength(1)
  })

  it('renders printer selectors', () => {
    const wrapper = shallow(<AssetGroupPrinting {...props()} />)
    expect(wrapper.find('PrintersSelection')).toHaveLength(1)
  })

  it('is hidden when we have no assets', () => {
    const wrapper = shallow(<AssetGroupPrinting {...props(0)} />)
    expect(wrapper.find('FormFor')).toHaveLength(0)
  })
})
