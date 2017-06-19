/** @babel */
/** @jsx etch.dom */

import etch from 'etch'
import { Disposable } from 'atom'
import Message from './message'

export default class Panel extends Disposable {
  constructor(turtle) {
    super()
    this.turtle = turtle
    this.showPanel = true
    this.view = new PanelView(turtle)
    this.provider = atom.views.addViewProvider(Panel,
      model => model.view.element)
    this.panel = atom.workspace.addBottomPanel({
      item: this,
      visible: this.shouldDisplay()
    })
    atom.workspace.onDidChangeActivePaneItem(() => {
      if (this.shouldDisplay()) {
        this.panel.show()
      } else {
        this.panel.hide()
      }
    })
  }

  togglePanel() {
    if (this.panel.visible) {
      this.showPanel = false
      this.panel.hide()
    } else {
      this.showPanel = true
      if (this.shouldDisplay()) {
        this.panel.show()
      }
    }
  }

  shouldDisplay() {
    if (!this.showPanel) {
      return false
    }
    let editor = atom.workspace.getActiveTextEditor()
    if (!editor) {
      return false
    }
    let grammar = editor.getGrammar()
    if (!grammar) {
      return false
    }
    if ((grammar.packageName === 'atom-turtle') ||
      (grammar.scopeName.indexOf('source.turtle') > -1)) {
      return true
    }
    return false
  }
}

class PanelView {
  constructor(turtle) {
    this.turtle = turtle
    this.showLog = true
    this.mouseMove = e => this.resize(e)
    this.mouseRelease = e => this.stopResize(e)
    etch.initialize(this)
  }

  async destroy() {
    await etch.destroy(this)
  }

  update() {
    return etch.update(this)
  }

  render() {
    let logs = undefined
    if (this.turtle.logger && this.turtle.logger.log.length > 0 &&
        this.showLog) {
      let items = this.turtle.logger.log.map(item =>
        <Message message={item} turtle={this.turtle}/>)
      logs =
        <atom-panel id="atom-turtle-logs" className="bottom">
          <div id="atom-turtle-panel-resizer" onmousedown={e => this.startResize(e)} />
          {items}
        </atom-panel>
    }

    let buttons =
      <div id="atom-turtle-controls">
        <ButtonView icon="play" tooltip="Turtle" click={ () => this.turtle.builder.build() } />
        <ButtonView icon="search" tooltip="Preview" click={ () => this.turtle.viewer.open() } />
        <ButtonView icon="list-ul" tooltip={ this.showLog ? "Hide build log" : "Show build log" } click={ () => this.toggleLog() } dim={!this.showLog} />
        <ButtonView icon="file-text-o" tooltip="Show raw log" click={ () => this.turtle.logger.open() } />
      </div>
    return (
      <div>
        {logs}
        {buttons}
      </div>
    )
  }

  toggleLog() {
    this.showLog = !this.showLog
    this.update()
  }

  resize(e) {
    height = Math.max(this.startY - e.clientY + this.startHeight, 25)
    document.getElementById('atom-turtle-logs').style.height = `${height}px`
    document.getElementById('atom-turtle-logs').style.maxHeight = 'none'
  }

  startResize(e) {
    document.addEventListener('mousemove', this.mouseMove, true)
    document.addEventListener('mouseup', this.mouseRelease, true)
    this.startY = e.clientY
    this.startHeight = document.getElementById('atom-turtle-logs').offsetHeight
  }

  stopResize(e) {
    document.removeEventListener('mousemove', this.mouseMove, true)
    document.removeEventListener('mouseup', this.mouseRelease, true)
  }
}

class ButtonView {
  constructor(properties = {}) {
    this.properties = properties
    etch.initialize(this)
    this.addTooltip()
  }

  async destroy() {
    if (this.tooltip) {
      this.tooltip.dispose()
    }
    await etch.destroy(this)
  }

  addTooltip() {
    if (this.tooltip) {
      this.tooltip.dispose()
    }
    this.tooltip = atom.tooltips.add(
      this.element, { title: this.properties.tooltip }
    )
  }

  update(properties) {
    this.properties = properties
    this.addTooltip()
    return etch.update(this)
  }

  render() {
    return (
      <i className={`fa fa-${this.properties.icon} atom-turtle-control-icon ${this.properties.dim?' atom-turtle-dimmed':''}`} onclick={this.properties.click} />
    )
  }
}
