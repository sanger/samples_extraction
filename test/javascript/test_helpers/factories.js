const CSRF_TOKEN = "1234"

let ASSET_GROUP_ID = 0

const buildEmptyActivityState = () => {
  return {
    //"csrfToken": CSRF_TOKEN,
    "activity":{
      "id": "1",
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

const generateAssetGroupId = () => {
  return ASSET_GROUP_ID++
}

const buildAssets = (numAssets) => {
  let list = []
  for (let i=0; i<numAssets; i++) {
    list.push({uuid: i})
  }
  return list
}

const buildAssetGroupData = (assetGroupId, numAssets) => {
  return({id: assetGroupId, assets: buildAssets(numAssets),
    assets_running: [],
    updateUrl: "http://"+assetGroupId})
}

const buildAssetGroups = (numGroups, numAssets) => {
  let obj = {}
  for (let i=0; i<numGroups; i++) {
    const assetGroupId = generateAssetGroupId()
    obj[assetGroupId] = buildAssetGroupData(assetGroupId, numAssets)
  }
  return obj
}

const buildActivityState = (numGroups, numAssets) => {
  let state = buildEmptyActivityState()

  state.assetGroups = buildAssetGroups(numGroups, numAssets)
  state.activity.selectedAssetGroup = Object.keys(state.assetGroups)[0]

  return state
}

export { buildAssets, buildAssetGroups, buildActivityState, buildAssetGroupData }
