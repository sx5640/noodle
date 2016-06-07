var visualization = (function() {

  var paused = true;
  var width;
  var height;
  var scene;
  var camera;
  var renderer;
  var boxMeshes;
  var groundPlane;
  var groundPlaneGeometry;
  var groundPlaneMaterial;
  var ambientLight;
  var directionalLight;
  var requestID;
  var visualizationRendered;

  return {

    //
    // View: Initializes Three.js
    //
    init: function() {
      // Set visualization rendered flag to false
      visualizationRendered = false;

      // Query container element for dimensions to set our Three.js canvas to
      width = $( '#threejs' ).width();
      height = $( '#threejs' ).height();

      console.log('Three.js setting width: ' + width + ', height: ' + height);

      // Initialize Three.js
      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera( 30, width/height, 1, 100000 );
      renderer = new THREE.WebGLRenderer( { alpha: true, antialias: true } );
      // renderer.setClearColor( 0xffffff, 0 );
      renderer.setSize( width, height );
      renderer.shadowMapEnabled = true;
      renderer.shadowMapSoft = true;

      // Set camera's z position
      camera.position.z = 2800;
      camera.position.y = 1250;
      camera.rotation.x = -.20;

      // Create ground plane
      var groundMaterial = new THREE.MeshPhongMaterial({
        color: 0xffffff
      });
      groundPlane = new THREE.Mesh(new THREE.PlaneGeometry(15000, 2000), groundMaterial);
      groundPlane.rotation.x = -Math.PI / 2;
      groundPlane.position.setY(-5);
      groundPlane.receiveShadow = true
      scene.add(groundPlane);

      // Create lights
      ambientLight = new THREE.AmbientLight( 0x888888 );
      scene.add(ambientLight);

      directionalLight = new THREE.DirectionalLight( 0xffffff, 1 );
      directionalLight.position.set(500, 1000, 250);
      directionalLight.position.multiplyScalar(1.3);
      directionalLight.castShadow = true;
      directionalLight.shadowCameraVisible = true;
      directionalLight.shadowMapWidth = 2048;
      directionalLight.shadowMapHeight = 2048;
      var d = 4000;
      directionalLight.shadowCameraLeft = -d;
      directionalLight.shadowCameraRight = d;
      directionalLight.shadowCameraTop = d;
      directionalLight.shadowCameraBottom = -d;
      directionalLight.shadowCameraFar = 15000;
      directionalLight.shadowDarkness = 0.2;
      scene.add(directionalLight);

      // Attach Three.js canvas to container element
      $( '#threejs' ).empty();
      $( '#threejs' ).append( renderer.domElement );

      // Define render callback animation function and pass it to requestAnimationFrame()
      var animationFrameCounter = 1;
      var animationFrameMax = 30;
      var render = function () {
        requestID = requestAnimationFrame( render );

        if (!paused) {
          if (!visualizationRendered) {
            if (boxMeshes) {
              for (var i = 0; i < boxMeshes.length; i++) {
                var cube = boxMeshes[i].mesh;
                var targetHeight = boxMeshes[i].targetHeight;
                var scale = animationFrameCounter/animationFrameMax;
                var sinScale = Math.sin(scale*Math.PI/2);
                sinScale = sinScale * sinScale;
                cube.scale.setY(sinScale);
                cube.position.setY(targetHeight * sinScale / 2);
              }
              animationFrameCounter++;
              if (animationFrameCounter > animationFrameMax) {
                visualizationRendered = true;
                animationFrameCounter = 1;
              }
            }
          } else {
            paused = true;
          }
          renderer.render( scene, camera );
        }
      };

      // Kick off the rendering process
      render();
    },

    //
    // View: Renders a 3D visualization of the given zones array to #visualization-container
    //
    render: function(articleZones, searchInfo, zones) {
      // Reset visualizationRendered flag so that it animates into view
      visualizationRendered = false;
      paused = false;
      var spacing = 16;

      // Remove all previously added objects from the scene, other than camera
      for (let i = scene.children.length - 1; i >= 0 ; i--) {
        let child = scene.children[ i ];

        if ( child !== camera && child !== groundPlane && child !== ambientLight && child !== directionalLight ) {
          scene.remove(child);
        }
      }

      // Create an array of Meshes that represent the zones
      boxMeshes = [];

      // Create one cube object for each zone (even empty zones) and add them to the scene
      var numArticleZones = articleZones.length;
      var maxVerticalSize = 0;
      console.log('numArticleZones: ', numArticleZones);
      for (var i = 0; i < numArticleZones; i++) {
        if (articleZones[i].count > 0) {
          var articleZone = articleZones[i];
          var verticalSize = 5 + articleZone.count * 80;
          if (verticalSize > maxVerticalSize) {
            maxVerticalSize = verticalSize;
            // console.log('MAX VERTICAL 1 ' + maxVerticalSize);
          }
          var boxGeometry = new THREE.BoxGeometry( 100, verticalSize, 300 );
          var boxMaterial = new THREE.MeshLambertMaterial( { color: 0x00c8ff, opacity: 1.0 } );
          var cube = new THREE.Mesh( boxGeometry, boxMaterial );
          var xScale = Math.max(0.05, 0.25 * 1/(articleZone.count * articleZone.count));
          cube.castShadow = true;
          cube.receiveShadow = true;
          cube.scale.setX(xScale);
          cube.position.set( (i - numArticleZones/2) * spacing, verticalSize/2, 0 );
          cube.material.opacity = verticalSize/500;
          boxMeshes.push( { mesh: cube, targetHeight: verticalSize } ); // Stash box for later use
          scene.add( cube );
          // console.log('>>>' + cube.position.x);
        }
      }

      // Create a cube object for each zone if provided
      if (searchInfo && zones) {
        var overallStartTime = searchInfo.start_time;
        var overallEndTime = searchInfo.end_time;
        var zoneStartTime, zoneEndTime;
        var jOverallStartTime = new Date(overallStartTime);
        var jOverallEndTime = new Date(overallEndTime);
        var jZoneStartTime, jZoneEndTime;
        var zoneOffsetStart, zoneOffsetEnd;
        // console.log('timeline start_time: ' + overallStartTime);
        // console.log('timeline end_time: ' + overallEndTime);
        // console.log('timeline start_time (JS): ' + jOverallStartTime);
        // console.log('timeline end_time (JS): ' + jOverallEndTime);

        for (var j = 0; j < zones.length; j++) {
          // console.log('ZONE # ' + j);
          zoneStartTime = zones[j].start_time;
          zoneEndTime = zones[j].end_time;
          jZoneStartTime = new Date(zoneStartTime);
          jZoneEndTime = new Date(zoneEndTime);
          // console.log('zone ' + j + ' start_time: ' + zoneStartTime);
          // console.log('zone ' + j + ' end_time: ' + zoneEndTime);
          // console.log('zone ' + j + ' start_time (JS): ' + jZoneStartTime);
          // console.log('zone ' + j + ' end_time (JS): ' + jZoneEndTime);

          zoneOffsetStart = (jZoneStartTime - jOverallStartTime) / (jOverallEndTime - jOverallStartTime);
          zoneOffsetEnd = (jZoneEndTime - jOverallStartTime) / (jOverallEndTime - jOverallStartTime);
          // console.log('zoneOffsetStart: ' + zoneOffsetStart);
          // console.log('zoneOffsetEnd: ' + zoneOffsetEnd);

          var zoneOffsetStartWorld = (zoneOffsetStart * numArticleZones * spacing) - ((numArticleZones/2) * spacing);
          var zoneOffsetEndWorld = (zoneOffsetEnd * numArticleZones * spacing) - ((numArticleZones/2) * spacing);
          var zoneWidthWorld = zoneOffsetEndWorld - zoneOffsetStartWorld;
          // console.log('zoneOffsetStartWorld: ' + zoneOffsetStartWorld);
          // console.log('zoneOffsetEndWorld: ' + zoneOffsetEndWorld);
          // console.log('zoneWidthWorld: ' + zoneWidthWorld);
          // console.log('MAX VERTICAL 2 ' + maxVerticalSize);
          var zoneBoxGeometry = new THREE.BoxGeometry( zoneWidthWorld, maxVerticalSize * 2, 10 );
          var zoneBoxMaterial = new THREE.MeshLambertMaterial( { color: 0x5f5f5f, opacity: 1.0 } );
          var zoneCube = new THREE.Mesh( zoneBoxGeometry, zoneBoxMaterial );
          zoneCube.position.set(zoneOffsetStartWorld + zoneWidthWorld/2, 0, -150);
          zoneCube.material.opacity = zones[j].hotness/10;
          scene.add(zoneCube);
        }
      }
    },

    //
    // View: Pause render
    //
    pause: function() {
      paused = true;
    },

    //
    // View: Unpause render
    //
    unpause: function() {
      paused = false;
    }
  }

}) ();
