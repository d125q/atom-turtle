/** @babel */
/** @jsx etch.dom */

import etch from 'etch'
import path from 'path'
import { Disposable } from 'atom'

export default class Message {
  constructor(properties = {}) {
    this.properties = properties
    etch.initialize(this)
  }

  async destroy() {
    await etch.destroy(this)
  }

  update(properties) {
    this.properties = properties
    return etch.update(this)
  }

  getIconClass() {
    let iconName = undefined
    switch (this.properties.message.type) {
      case 'error':
        iconName = 'fa-times-circle'
        break;
      case 'warning':
        iconName = 'fa-exclamation-circle'
        break;
      default:
        iconName = 'fa-info-circle'
    }
    return `fa ${iconName} atom-turtle-log-icon`
  }

  render() {
    let clickable = false
    let file = <span />
    let line = <span />
    if (this.properties.message.file != null) {
      clickable = true
      file = <span>{path.basename(this.properties.message.file)}</span>
      if (this.properties.message.line > 0) {
        line = <span>:{this.properties.message.line} </span>
      }
    }
    let handleClick = () => this.handleClick(this.properties.message.file, this.properties.message.line)
    return (
      <div className={`atom-turtle-log-message${clickable ? ' atom-turtle-log-clickable' : ''}`} onclick={handleClick}>
        <i className={this.getIconClass()} />
        {file}
        {line}
        {this.properties.message.text}
      </div>
    )
  }

  handleClick(file, line) {
    if (file) {
      atom.workspace.open(file, { initialLine: line > 0 ? line - 1 : 0 })
    }
  }
}
