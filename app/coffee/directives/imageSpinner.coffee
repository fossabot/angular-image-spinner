angular.module('imageSpinner')

# Default settings for spin.js library.
.constant 'imageSpinnerDefaultSettings',
    lines     : 9
    length    : 10
    width     : 2
    radius    : 3
    corners   : 1
    rotate    : 0
    direction : 1
    color     : '#000'
    speed     : 1
    trail     : 10
    shadow    : false
    hwaccel   : false
    className : 'spinner'
    zIndex    : 2000000000
    top       : '50%'
    left      : '50%'

.directive 'imageSpinner', [
    '$window', 'imageSpinnerDefaultSettings'
    ($window, DefaultSettings) ->
        ImageLoader = $window.Image

        class SpinnerBuilder
            constructor: (@el, @settings) ->
                settings ?= {}
                settings = angular.extend(DefaultSettings, settings)
                @spinner = new Spinner(settings)

                @container = @el.parent()
                @container.hide = =>
                    @container.css('display', 'none')
                @container.show = =>
                    @container.css('display', 'block')

                # wait until image is loading
                @loader = new ImageLoader()
                @loader.onload = => @load()

            setWidth: (width) ->
                width  = "#{width.replace(/px/, '')}px"
                angular.element(@container)
                    .css('width', width)

            setHeight: (height) ->
                height  = "#{height.replace(/px/, '')}px"
                angular.element(@container)
                    .css('height', height)

            show: ->
                # set src for loading the image and show the spinner
                @loader.src = @el.attr('src')
                @el.css('display', 'none')
                @spin()

            load: =>
                @unspin()
                @el.css('display', 'block')
                @container.css('display', 'block')

            spin: ->
                return if @hasSpinner
                @hasSpinner = true
                @spinner.spin(@container[0])

            unspin: ->
                return unless @hasSpinner
                @hasSpinner = false
                @spinner.stop()

        SPINNER_CLASS_NAME = 'spinner-container'

        isEmpty = (value) ->
            value is undefined or
            value is null or
            value is ''

        link = (scope, element, attributes) ->
            # Wrap img by container with fixed width, height using the img
            # attributes width and height
            container = angular
                .element("<div>")
                .addClass(SPINNER_CLASS_NAME)
                .css('position', 'relative')
            element.wrap(container)

            image = angular.element(element)

            # In case if user passed hash with setting using
            # image-spinner-settings attribute we will eval it and pass to the
            # spin.js
            settings = attributes.imageSpinnerSettings
            settings ?= {}
            settings = scope.$eval(settings)

            spinner = new SpinnerBuilder(image, settings)

            do (spinner) =>
                render = (src) ->
                    return if isEmpty(src) ||
                        isEmpty(image.attr('width')) ||
                        isEmpty(image.attr('height'))
                    spinner.show()


                flow = ->
                    src = image.attr('src')

                    if showable()
                        render(src)

                        unless isEmpty(src)
                            spinner.container.show()
                    else
                        spinner.unspin()
                        spinner.container.hide()

                showable = ->
                    !image.hasClass('ng-hide')

                # If we are using ng-hide or ng-show directives we need to track
                # the showable status for the img. Lets render spinner in case if
                # it's showable only.
                scope.$watch (-> showable()), (value) ->
                    return unless value?
                    flow()

                scope.$on '$destroy', ->
                    spinner.container.hide()

                attributes.$observe 'ng-src', (src) ->
                    return if isEmpty(src)
                    flow()

                attributes.$observe 'src', (src) ->
                    return if isEmpty(src)
                    flow()

                attributes.$observe 'width'  , (width) ->
                    return if isEmpty(width)
                    spinner.setWidth(width)
                    render(image.attr('src'))

                attributes.$observe 'height' , (height) ->
                    return if isEmpty(height)
                    spinner.setHeight(height)
                    render(image.attr('src'))

        return {
            restrict : 'A'
            link     : link
            scope    : {}
        }
]

