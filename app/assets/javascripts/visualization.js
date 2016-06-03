var visualization = (function() {

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
      width = $( '#visualization-container' ).width();
      height = $( '#visualization-container' ).height();

      // Initialize Three.js
      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera( 30, width/height, 1, 100000 );
      renderer = new THREE.WebGLRenderer( { alpha: true, antialias: true } );
      // renderer.setClearColor( 0xffffff, 0 );
      renderer.setSize( width, height );
      renderer.shadowMapEnabled = true;
      renderer.shadowMapSoft = true;

      // Set camera's z position
      camera.position.z = 2500;
      camera.position.y = 1500;
      camera.rotation.x = -.35;

      // Create ground plane
      var groundMaterial = new THREE.MeshPhongMaterial({
        color: 0xffffff
      });
      groundPlane = new THREE.Mesh(new THREE.PlaneGeometry(5000, 5000), groundMaterial);
      groundPlane.rotation.x = -Math.PI / 2;
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
      var d = 2000;
      directionalLight.shadowCameraLeft = -d;
      directionalLight.shadowCameraRight = d;
      directionalLight.shadowCameraTop = d;
      directionalLight.shadowCameraBottom = -d;
      directionalLight.shadowCameraFar = 10000;
      directionalLight.shadowDarkness = 0.2;
      scene.add(directionalLight);

      // Attach Three.js canvas to container element
      $( '#visualization-container' ).empty();
      $( '#visualization-container' ).append( renderer.domElement );

      // Define render callback animation function and pass it to requestAnimationFrame()
      var animationFrameCounter = 1;
      var animationFrameMax = 30;
      var render = function () {
          requestID = requestAnimationFrame( render );

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
                // console.log(boxMesh);
              }
              animationFrameCounter++;
              if (animationFrameCounter > animationFrameMax) {
                visualizationRendered = true;
                animationFrameCounter = 1;
              }
            }
          }

          renderer.render( scene, camera );
      };

      // Kick off the rendering process
      render();
    },

    //
    // View: Renders a 3D visualization of the given zones array to #visualization-container
    //
    render: function(zones) {
      // Reset visualizationRendered flag so that it animates into view
      visualizationRendered = false;

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
      var numZones = zones.length;
      for (var i = 0; i < numZones; i++) {
        console.log('i: ', i);
        if (zones[i].count > 0) {
          var spacing = 12;
          var zone = zones[i];
          var verticalSize = 25 + zone.count * 500;
          var boxGeometry = new THREE.BoxGeometry( 100, verticalSize, 300 );
          var boxMaterial = new THREE.MeshLambertMaterial( { color: 0x00c8ff, opacity: 1.0 } );
          var cube = new THREE.Mesh( boxGeometry, boxMaterial );
          cube.castShadow = true;
          cube.receiveShadow = true;
          cube.scale.setX(0.033);
          cube.position.set( (numZones/2 - i) * spacing, verticalSize/2, 0 );
          cube.material.opacity = verticalSize/625;
          boxMeshes.push( { mesh: cube, targetHeight: verticalSize } ); // Stash box for later use
          scene.add( cube );

          console.log('article count: ', zone.count);
        }
      }
    }
  }

}) ();
