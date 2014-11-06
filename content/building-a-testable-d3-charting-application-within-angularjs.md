Title: Building a Testable D3 Charting Application Within Angular.js
Date: 2014-10-04
Category: Graphing
Tags: charting, d3, best-practices, testing
Slug: building-a-testable-d3-charting-application-within-angularjs
Author: Fred Battista
Avatar: fred-battista

Why this post?

> * Most of the examples on d3js.org are much smaller, proof of concept applications which funcion well as a single page app but not necessarily in the reuseable context of a larger, more complex app.

> * This post assumes familiarity with Angular.js' concepts of Controllers, Directives, and Services, Jasmine's testing framework, and d3 concepts like axis, scale, and path.

> * d3.js' customizeability can rapidly lead to a fragile codebase within larger applications. We provide some suggestions on how to modularize and then test a charting application.

*nb: At TrackMaven, we use Coffeescript+Angular to manage our frontend.*

Graphing is a core feature of TrackMaven's application. As we added more graph types, it became obvious that a monolithic hunk of coffeescript was not an ideal foundation. 

Our solution was to separate the graphing bloc into separate factories, services, and directories to enable code reuse and testing along the lines of the actual components of the SVG itself. 

We think that everything that was previously a section of chained definitions (e.g `element.attr('','')..`) could be promoted to its own function within a service. 

This means that our graph's many layers and variables which were all previously defined within a single directive like this:


	svg = d3.select(element[0])
	y = d3.scale.linear()
	x = d3.time.scale()


now look like this:

	angular.module('graphing.directives.visualizer')

	.service('graphBase', (dateFilter) ->
    	class GraphBase
        	generate: (element) ->
            	@generateSvg(element)
            	@generateAxises()
            	...

        	generateSvg: (element) ->
            	@svg = d3.select(element[0])
            	...

	        generateAxises: ->
            	@yAxis = d3.svg.axis()
            	@xAxis = d3.svg.axis()
            	...
            	
            svgContainer: ->
            	@svgContainer = @svg.append("svg:g")
                	.attr("class", "svg-container")
                	.attr("transform", "translate(#{@sidePadding})")

	            return @svgContainer
     
            graphContainer: ->
            	@graphContainer = @svgContainer.append("svg:g")
                	.attr("class", "graph-canvas")
                	.attr("id", "graph-svg")

     	       	@graphContainer.append("svg:rect")
                	.attr("width", @width)
                	.attr("height", @height)
                	.style("fill", 'white')
                	
                return @graphContainer
                
The advantages of this approach may not be immediately obvious (extra work! why?) but within the context of d3 and enterprise software they are important.

**1. Separate definition of container from its initialization**

Firstly, the defenition/creation of graphical layers has been separated from their initialization. This can be somewhat confusing but is a consequence of the [SVG spec](http://www.w3.org/TR/SVG/) having no support for a z-index. There is no way to change the 'stacked' order of elements on an SVG except by manually redrawing the elements again in the correct order.

By separating the container definition from the initialization it becomes much easier to correctly draw and test the order of SVG elements. This is of especial importance when clipping masks are in play - untangling long code blocks is annoying. 

**2. Easily change and re-initialize graph types**

With the returned values on the graphBase object it becomes trivial to alter the properties as needed. If I need to give the svgContainer a green background it is as simple as: `@svgContainer.style('background-color','green')` WHEREVER I need to make the change. I do not need to hunt for the block where the `svgContainer` is created.

**3. Testing is easier/feasible**

Testing is easier with this approach. Previously, any change in the monolithic code block had the potential ta affect every test. With the modular approach, your integration tests may fail but you unit tests have a much higher chance of survival.

With the above setup it is possible to mock and test the creation of elements with specific ids on any given SVG. This is very difficult to do with a giant block of code.  

For instance, this is the first test of our graph tooltips:

        it 'should correctly render tooltips', ->
            tooltips.redraw(mockData)
            tips = d3.select(element[0]).selectAll('.graph-tooltip')[0]
            expect(tips.length).toEqual(1)
            expect(tips[0].style['left']).toEqual('32px')
            expect(tips[0].style['top']).toEqual('10px')
            expect(element[0].innerText).toContain('100')
            expect(element[0].innerText).toContain('XXXXXX-BBBBB')

### None of the above is revolutionary

Nothing above is news: modularizing and re-factoring for code reuse is good practice generally. However, client side graphing code can be difficult to unravel and we think that our approach of service modularization is helpful.

### Next steps

We expect to go deeper with this modularization as we add graph types. Specifically, we want to modularize the `brush` interaction to flex and activate across different SVG elements. Creating a separate `graphBrush` service is likely.


*Additional resources which cover similar material:*

*  [d3.chart: a framework for building reusable charts with d3.js](http://misoproject.com/d3-chart/) 
*  [Mike Bostok's 'Towards Reuseable Charts'](http://bost.ocks.org/mike/chart/)
*  [d3 and Test-Driven-Development](http://pivotallabs.com/d3-test-driven-development/)
*  [Great set of example code in vanilla JS on Jasmine-driven testing of D3](https://github.com/stevenalexander/d3-testing)
