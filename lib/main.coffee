cache = []
clearCache = () ->
  cache = []

reloadCache = () ->
  values = atom.config.get('glass-syntax.backgroundImages')
  cache = (load image for image in values)

load = (filename) ->
  newImage = new Image()
  newImage.src = filename
  return newImage

backgroundID = null
disableBackground = () ->
  if backgroundID isnt null
    clearInterval(backgroundID)
    backgroundID = null
    document.querySelector('atom-workspace').style.backgroundImage = ''

getRandomInt = (min, max) ->
  return Math.floor(Math.random() * (max - min)) + min;

currentIndex = -1

enableBackground = (delayTime) ->
  if backgroundID isnt null
    clearInterval(backgroundID)
  currentIndex = -1
  changeBackground()
  backgroundID = setInterval(changeBackground, delayTime)

changeBackground = () ->
  newIndex = currentIndex
  while newIndex is currentIndex and cache.length != 1
    newIndex = getRandomInt(0, cache.length)
  currentIndex = newIndex
  background = atom.config.get('glass-syntax.backgroundImages')[currentIndex]
  document.querySelector('atom-workspace').style.backgroundImage = 'url(' + background + ')'

configChange = () ->
  delayTime = atom.config.get('glass-syntax.delayTime')
  backgrounds = atom.config.get('glass-syntax.backgroundImages')
  if backgrounds is [] or backgrounds is undefined or delayTime is undefined
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
      description: 'The images that will be used as backgrounds, separated by commas.'
      type: 'array'
      default: []
      items:
        type: 'string'

  activate: (state) ->
    atom.config.observe 'glass-syntax.backgroundImages', (newValue) ->
      configChange()
    atom.config.observe 'glass-syntax.delayTime', (newValue) ->
      configChange()
    atom.config.observe 'glass-syntax.transitionTime', (newValue) ->
      console.log('background-image ' + newValue + 'ms linear;')
      document.querySelector('atom-workspace').style.transition = 'background-image ' + newValue + 's linear'

  deactivate: ->
    clearCache()
