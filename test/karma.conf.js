// Generated by CoffeeScript 2.1.1
(function() {
  // Karma configuration
  // run with `node_modules/karma/bin/karma start`
  module.exports = function(config) {
    return config.set({
      // base path, that will be used to resolve files and exclude
      basePath: "../",
      // frameworks to use
      frameworks: ['browserify', 'jasmine'],
      // list of files / patterns to load in the browser
      files: [
        "bower_components/zeroclipboard/ZeroClipboard.min.js",
        "bower_components/underscore/underscore.js",
        "bower_components/jQuery/dist/jquery.min.js",
        "bower_components/angular/angular.min.js",
        "bower_components/angular-ui-router/release/angular-ui-router.min.js",
        "bower_components/angular-sanitize/angular-sanitize.min.js",
        "bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js",
        "bower_components/angular-mocks/angular-mocks.js",
        "bower_components/ng-clip/dest/ng-clip.min.js",
        "bower_components/ng-csv/build/ng-csv.min.js",
        "bower_components/moment/min/moment.min.js",
        "lib/moment-interval.js",
        "bower_components/d3/d3.min.js",
        // "src/druid.coffee"
        "test/unit/**/*.spec.coffee",
        "node_modules/deep-diff/releases/deep-diff-0.1.7.min.js"
      ],
      preprocessors: {
        '**/*.coffee': ['browserify']
      },
      // 'lib/app.js': ['coverage']
      browserify: {
        extensions: ['.coffee'],
        transform: ['coffeeify']
      },
      coffeePreprocessor: {
        // options passed to the coffee compiler
        options: {
          sourceMap: true
        }
      },
      // list of files to exclude
      exclude: [],
      // test results reporter to use
      // possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
      reporters: ['progress', 'coverage'],
      // web server port
      port: 8080,
      // enable / disable colors in the output (reporters and logs)
      colors: true,
      // level of logging
      // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
      logLevel: config.LOG_INFO,
      // enable / disable watching file and executing tests whenever any file changes
      autoWatch: true,
      // Start these browsers, currently available:
      // - Chrome
      // - ChromeCanary
      // - Firefox
      // - Opera (has to be installed with `npm install karma-opera-launcher`)
      // - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
      // - PhantomJS
      // - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
      browsers: ["Chrome"],
      // If browser does not capture in given timeout [ms], kill it
      captureTimeout: 60000,
      // Continuous Integration mode
      // if true, it capture browsers, run tests and exit
      singleRun: false
    });
  };

}).call(this);
