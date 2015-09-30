fs = require 'fs'

currentIndex = -1
backgroundID = null
filelist = []
cache = []
clearCache = () ->
  cache = []

getType = (filepath) ->
  if fs.existsSync filepath
    stats = fs.statSync filepath
    if stats.isFile()
      return 'file'
    else if stats.isDirectory()
      return 'directory'
  return 'unknown'

getFilelist = (paths) ->
  fl = []
  for filename in paths
    filetype = getType filename
    if filetype is 'directory'
      fl = fl.concat(parseDirectory filename)
    else
      fl.push(filename)
  return fl

parseDirectory = (dirPath) ->
  contents = fs.readdirSync(dirPath)
  contents = (dirPath + '/' + filename for filename in contents)
  return getFilelist contents

reloadCache = () ->
  paths = atom.config.get('glass-syntax.backgroundImages')
  filelist = getFilelist paths
  cache = (load filename for filename in filelist)

load = (filename) ->
  newImage = new Image()
  newImage.src = filename
  return newImage

disableBackground = () ->
  if backgroundID isnt null
    clearInterval(backgroundID)
    currentIndex = -1
    backgroundID = null
    workspace = document.querySelector('atom-workspace')
    workspace.style.backgroundImage = ''
    workspace.style.transition = ''

getRandomInt = (min, max) ->
  return Math.floor(Math.random() * (max - min)) + min;

enableBackground = (delayTime) ->
  if backgroundID isnt null
    clearInterval(backgroundID)
  changeBackground()
  backgroundID = setInterval(changeBackground, delayTime)

changeBackground = () ->
  newIndex = currentIndex
  while newIndex is currentIndex and filelist.length isnt 1
    newIndex = getRandomInt(0, filelist.length)
  if filelist.length is 1
    newIndex = 0
  currentIndex = newIndex
  background = filelist[currentIndex]
  document.querySelector('atom-workspace').style.backgroundImage = 'url(' + background + ')'

configChange = () ->
  delayTime = atom.config.get('glass-syntax.delayTime')
  backgrounds = atom.config.get('glass-syntax.backgroundImages')
  if backgrounds is undefined or backgrounds.length is 0 or delayTime is undefined
    clearCache()
    disableBackground()
  else
    reloadCache()
    enableBackground(delayTime * 1000)

module.exports =
  config:
    delayTime:
      title: 'Delay Time'
      description: 'The amount of time between images, in seconds.'
      type: 'number'
      default: 30
      minimum: 2
    transitionTime:
      title: 'Transition Time'
      description: 'The amount of time spent smoothly changing between images, in seconds'
      type: 'number'
      default: 6
      minimum: 0
    backgroundImages:
      title: 'Background Images'
      description: 'The images that will be used as backgrounds, separated by commas. Folder names are accepted, and will be recursively examined for files, there may be non-fatal errors if there are any files that are not images in the folder. Full http and https urls are accepted as well, but will give a blank screen with a fail symbol if the image cannot be found, due to network issues or otherwise. Use "/", not "\\" to separate folders'
      type: 'array'
      default: []
      items:
        type: 'string'

  activate: (state) ->
    atom.config.onDidChange 'glass-syntax.backgroundImages', (newValue) ->
      configChange()
    atom.config.onDidChange 'glass-syntax.delayTime', (newValue) ->
      configChange()
    atom.config.observe 'glass-syntax.transitionTime', (newValue) ->
      document.querySelector('atom-workspace').style.transition = 'background-image ' + newValue + 's linear'
    configChange()

  deactivate: () ->
    clearCache()
    disableBackground()
