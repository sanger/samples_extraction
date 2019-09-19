const CSRF_TOKEN = "1234"

const buildActivityState = () => {
  return {
    "csrfToken": CSRF_TOKEN,
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
}

const buildAsset = () => {

}

const buildAssetGroup = (obj) => {
  return Object.assign({"id": generateAssetGroupId()})
}

const buildActivityState = (assetGroups, selectedAssetGroup) => {
  if (!selectedAssetGroup) {
    selectedAssetGroup = Object.keys(assetGroups)[0]
  }
  let activityState = buildActivityStateWithoutAssetGroups()
  activityState.activity.selectedAssetGroup = selectedAssetGroup
  return Object.assign({}, activityState, { assetGroups })
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

test('displays the AssetGroupEditor component', () => {
  global.App = {
    cable: {
      subscriptions: {
        create: jest.fn()
      }
    }
  }
  let stateWithGroup = Object.assign({}, testing_props, {
    assetGroups: {
      123: {"id": 123, updateUrl: 'http://updateUrl/123', assets: []}
    },

  })
  stateWithGroup.activity.selectedAssetGroup = 123

  const wrapper = mount(<Activity {...stateWithGroup} />);
  //const wrapper = mount(<div />);
  expect(wrapper.find('AssetGroupEditor')).toHaveLength(1);
});
