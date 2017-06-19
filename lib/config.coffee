module.exports =
  compiler:
    title: 'Turtle compiler to use'
    order: 1
    description: 'Path to the Turtle compiler.'
    type: 'string'
    default: 'turtle'
  ghostscript:
    title: 'Ghostscript executable'
    order: 2
    description: 'Path to the Ghostscript executable'
    type: 'string'
    default: 'gs'
  build_after_save:
    title: 'Run Turtle after saving'
    order: 3
    description: 'Whether to run Turtle after saving a `.turtle` file.'
    type: 'boolean'
    default: true
  save_on_build:
    title: 'Save files before building'
    order: 4
    description: 'Save all `.turtle` files prior to building them.'
    type: 'boolean'
    default: false
  preview_after_build:
    title: 'Preview PDF after building'
    order: 5
    description: 'Use PDF viewer to preview the generated PDF file after \
                  successfully running Turtle.'
    type: 'boolean',
    default: true
  hide_log_if_successful:
    title: 'Hide Turtle log messages on successful build'
    order: 6
    description: 'Hide the Turtle log panel after a successful build.'
    type: 'boolean'
    default: true
  extensions_to_clean:
    title: 'Files to clean'
    order: 7
    description: 'File extensions that should be removed.'
    type: 'string'
    default: '*.ast, *.pt'
  clean_after_build:
    title: 'Clean auxiliary files after building'
    order: 8
    description: 'Clean all auxiliary files after a successful build.'
    type: 'boolean'
    default: false
