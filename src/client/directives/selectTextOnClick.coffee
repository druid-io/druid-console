module.exports = ->
  restrict: 'A',
  link: ($scope, $el) ->
    $el.on 'click', () ->
      window.getSelection().selectAllChildren($el[0])
