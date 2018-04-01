import React from 'react'

class AlertDisplay extends React.Component {
  constructor(props) {
    super(props)
    this.onRemoveMsg = this.onRemoveMsg.bind(this)
    this.renderMessage = this.renderMessage.bind(this)
  }
  onRemoveMsg(m, pos) {
    this.props.onRemoveErrorMessage(m,pos)
  }
  renderMessage(m, pos) {
    const destroyMessage = $.proxy(this.onRemoveMsg, this, m, pos)

    if (m.type=='info') {
      setTimeout(destroyMessage, 3000)
    }
    return (<div key={pos} className={"alert alert-"+m.type}>
    {m.msg}
    <button onClick={destroyMessage} className="close" type="button"><span>&times;</span></button>
  </div>)
    }
  render() {
    return(
      this.props.messages.map(this.renderMessage)
    )
  }
}

export default AlertDisplay
