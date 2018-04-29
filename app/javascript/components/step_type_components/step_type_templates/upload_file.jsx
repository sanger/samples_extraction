import React, { Component } from 'react'

import FineUploaderTraditional from 'fine-uploader-wrappers'
import Gallery from 'react-fine-uploader'

// ...or load this specific CSS file using a <link> tag in your document
import 'react-fine-uploader/gallery/gallery.css'

function uploaderOptions(props) {
  return(
    {
      options: {
        chunking: {
            enabled: true
        },
        deleteFile: {
            enabled: true,
            endpoint: '/asset_groups/'+props.asset_group.id+'/upload'
        },
        request: {
            endpoint: '/asset_groups/'+props.asset_group.id+'/upload',
            customHeaders: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }
        },
        retry: {
            enableAuto: true
        }
      }
    }        
  )
}

class UploadFile extends Component {
    render() {
        return (
            <Gallery uploader={ new FineUploaderTraditional(uploaderOptions(this.props)) } />
        )
    }
}

export default UploadFile
