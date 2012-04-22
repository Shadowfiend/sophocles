commitOffsets = []

adjustMessageHeight = ->
  $('.message, .diffs').css({ height: "#{window.innerHeight}px" })

$(document).ready ->
  $commits = $('section.commit')
  $commits.each ->
    commitOffsets.push [this.offsetTop, this]

  bodyHeight = document.body.offsetHeight

  adjustMessageHeight()
  $commits.add('h1').each( ->
    $(this).css top: this.offsetTop
  ).each ->
    $(this).css position: 'fixed'

  $('body').css height: "#{bodyHeight}px"

$(window).resize adjustMessageHeight

lastScrollTop = 0
currentConsiderationIndex = 0
signOf = (num) -> if num < 0 then -1 else 1
compareBySign = (sign, comparator, start, end) ->
  if sign < 0
    start < comparator
  else
    comparator < end
$(document).scroll (event) ->
  scrollTop = document.scrollTop || document.body.scrollTop
  scrollChange = scrollTop - lastScrollTop
  lastScrollTop = scrollTop

  commit = commitOffsets[currentConsiderationIndex][1]
  nextConsiderationIndex = currentConsiderationIndex + signOf(scrollChange)
  nextOffsetParts = commitOffsets[nextConsiderationIndex]

  if nextOffsetParts?
    [nextOffset, nextCommit] = nextOffsetParts

  scrollingElement = undefined
  diffs = $(commit).children('.diffs')
  nextDiffs = $(nextCommit).children('.diffs')
  if parseInt($(commit).css('top')) * signOf(scrollChange) <= 0 &&
     compareBySign(signOf(scrollChange), diffs[0].scrollTop, 0, diffs[0].scrollHeight - diffs[0].offsetHeight)
    scrollingElement = diffs[0]
  else if parseInt($(nextCommit).css('top')) * signOf(scrollChange) <= 0
    if compareBySign(signOf(scrollChange), nextDiffs[0].scrollTop, 0, nextDiffs[0].scrollHeight - nextDiffs[0].offsetHeight)
      scrollingElement = nextDiffs[0]
    else
      currentConsiderationIndex = nextConsiderationIndex

  if scrollingElement?
    scrollingElement.scrollTop += scrollChange
  else
    $('h1, section.commit').each ->
      $this = $(this)
      top = parseInt $this.css('top')
      $this.css 'top': "#{top - scrollChange}px"
