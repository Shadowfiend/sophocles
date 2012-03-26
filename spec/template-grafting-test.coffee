require './test-helpers.coffee'

vows
  .describe('Grafting HTML templates')
  .addBatch(
    'Given an HTML template':
      topic: ->
        """
        <div class="item">Whazak</div>
        <a class="link" href="booyan">Whazam</a>
        <div class="nested">
          <span class="magic">Boom</span>
        </div>
        """

      'when you graft plain text to an element':
        topic: graftAndjQueryHtml('.item': 'booyan')

        "then that element's text will be set": (errors, $html) ->
          assert.isNull errors
          assert.equal $html.find('.item').text(), 'booyan'

      'when you graft plain text to an attribute':
        topic: graftAndjQueryHtml('.link[href]': '/magic')

        "then that element's attribute will be set": (errors, $html) ->
          assert.isNull errors
          assert.equal $html.find('.link').attr('href'), '/magic'

        "and that element's text will not be set": (errors, $html) ->
          assert.notEqual $html.find('.link').text(), '/magic'

      'when you graft plain text to add to an attribute':
        topic: graftAndjQueryHtml('.item[class+]': 'info')

        "then that element's attribute will have a space and the text appended": (errors, $html) ->
          assert.isNull errors
          assert.equal $html.find('.item').attr('class'), 'item info'

      'when you graft jQueryied HTML to an element':
        topic:
          withjQueryAndjQueryHtml ($, htmlize) =>
            $('html').graft '.magic': $('<a>').text('author').addClass('magic').attr('href', 'link')

            htmlize()

        'then the given element should be replaced with the jQueryied HTML': (errors, $html) ->
          assert.isNull errors

          assert.equal $html.find('a.magic').length, 1
          assert.equal $html.find('a.magic').text(), 'author'
          assert.equal $html.find('a.magic').attr('href'), 'link'

      'when you graft with a nested object':
        topic: graftAndjQueryHtml(
          '.nested':
            'span': 'hi',
            'span [class]': 'boom'
        )

        "then the nested object should be used to graft the matched element": (errors, $html) ->
          assert.isNull errors

          assert.equal $html.find('.nested span').text(), 'hi'
          assert.equal $html.find('.nested span').attr('class'), 'boom'
  )
  .addBatch(
    'Given an HTML template':
      topic: """
        <ul>
          <li class="author">
            <h3>Ernest Hemmingway</h3>
            <div class="birth-date">Born on <span class="date">September 3rd</span>.</div>
          </li>
        </ul>
        """

      'and a list of authors':
        topic: [
          { name: 'Roald Dahl', birthDate: 'September 13th' },
          { name: 'Norton Juster', birthDate: 'June 2nd' },
          { name: 'F. Scott Fitzgerald', birthDate: 'September 24th' }
        ]

        'when you graft the authors to an element':
          topic: (authors, html) ->
            graftAndjQueryHtml(
              'li.author':
                authors.map (author) ->
                  'h3': author.name
                  '.birth-date span.date': author.birthDate
            ).call(this, html)

            return

          'then there should be 3 elements resulting': (errors, $html) ->
            assert.equal $html.find('li.author').length, 3

          'and each element should have the appropriate author info bound': (errors, $html) ->
            $elements = [
              $html.find('li.author:eq(0)'),
              $html.find('li.author:eq(1)'),
              $html.find('li.author:eq(2)')
            ]

            assert.equal $elements[0].find('h3').text(), 'Roald Dahl'
            assert.equal $elements[0].find('span.date').text(), 'September 13th'
            assert.equal $elements[1].find('h3').text(), 'Norton Juster'
            assert.equal $elements[1].find('span.date').text(), 'June 2nd'
            assert.equal $elements[2].find('h3').text(), 'F. Scott Fitzgerald'
            assert.equal $elements[2].find('span.date').text(), 'September 24th'
  ).export module
