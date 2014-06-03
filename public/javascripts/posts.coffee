commitOffsets = []

adjustMessageHeight = ->
  $('.message, .diffs').css({ height: "#{window.innerHeight}px" })

$(document).ready ->
  $commits = $('section.commit')
  $commits.each -> commitOffsets.push [this.offsetTop, this]

  bodyHeight = document.body.offsetHeight

  adjustMessageHeight()
  $commits.add('h1').each( ->
    $(this).css top: this.offsetTop
  ).each ->
    $(this).css position: 'fixed'

  $('body').css height: "#{bodyHeight}px"

$(window).resize adjustMessageHeight

signOf = (num) -> if num < 0 then -1 else 1
compareBySign = (sign, comparator, start, end) ->
  if sign < 0
    start < comparator
  else
    comparator < end

# Runs a scroll to the next element. If scrollChange would scroll past
# the next element, returns the remaining scrollChange. Otherwise, returns
# 0.
scrollToNextElement = (scrollChange, lastIndex, lastTop) ->
  sign = signOf scrollChange

  index = lastIndex + sign
  [offsetTop, element] = commitOffsets[index]
  diffChild = $(element).children('.diffs')[0]

  if diffChild?
    [scrollChange, lastTop] = scrollNext diffChild, scrollChange, lastTop

  console.log "Post internal: #{scrollChange}"
  return [scrollChange, lastIndex, lastTop, 0] if scrollChange <= 0

  actualScroll =
    if sign is 1
      remainingScroll = scrollChange - (element.scrollHeight - element.offsetHeight)
      console.log "Externally remaining: #{remainingScroll} vs #{scrollChange}"
      Math.min Math.abs(scrollChange), remainingScroll
    else
      currentScroll = element.scrollTop
      Math.min Math.abs(scrollChange), currentScroll
  
  if (sign is 1 and remainingScroll > scrollChange) ||
     element.scrollTop > Math.abs(scrollChange)
    index = lastIndex
  [scrollChange - actualScroll, index, lastTop + sign * actualScroll, actualScroll]

scrollNext = (element, scrollChange, lastTop) ->
  sign = signOf scrollChange

  actualScroll =
    if sign is 1
      remainingScroll = element.scrollHeight - element.offsetHeight - element.scrollTop
      console.log "Remaining: #{remainingScroll} vs #{scrollChange}"
      Math.min Math.abs(scrollChange), remainingScroll
    else
      currentScroll = element.scrollTop
      Math.min Math.abs(scrollChange), currentScroll

  element.scrollTop += sign * actualScroll
  console.log "Internal: #{sign * actualScroll}, #{element.scrollTop}", element
  [scrollChange - actualScroll, lastTop + sign * actualScroll]
  
currentIndex = -1
lastScrollTop = 0
$(document).scroll (event) ->
  scrollTop = originalTop = document.scrollTop || document.body.scrollTop
  currentScrollChange = scrollChange = scrollTop - lastScrollTop

  console.log "Total change: #{scrollChange} @ #{currentIndex}."
  overallChange = 0
  while currentScrollChange > 0
    [currentScrollChange, currentIndex, scrollTop, actualScroll] =
      scrollToNextElement currentScrollChange, currentIndex, scrollTop

    console.log "Result: #{actualScroll}; at #{currentScrollChange}"

    overallChange += actualScroll

  lastScrollTop = scrollTop
  console.log "In the end, #{overallChange}"

  $('h1, section.commit').each ->
    $this = $(this)
    top = parseInt $this.css('top')
    $this.css 'top': "#{top - overallChange}px"

































