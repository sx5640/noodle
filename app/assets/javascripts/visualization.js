var visualization = (function() {

  var width;
  var height;
  var scene;
  var camera;
  var renderer;
  var meshes;
  var geometry;
  var material;

  return {

    //
    // View: Initializes Three.js
    //
    init: function() {
      // Query container element for dimensions to set our Three.js canvas to
      width = $( '#visualization-container' ).width();
      height = $( '#visualization-container' ).height();

      // Initialize Three.js
      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera( 35, width/height, 0.1, 1000 );
      renderer = new THREE.WebGLRenderer( { alpha: true, antialias: true } );
      renderer.setClearColor( 0xffffff, 0 );
      renderer.setSize( width, height );

      // Attach Three.js canvas to container element
      $( '#visualization-container' ).empty();
      $( '#visualization-container' ).append( renderer.domElement );

      // Set camera's z position
      camera.position.z = 15;
      camera.position.y = 7;
      camera.rotation.x = -.2;

      // Define render callback animation function and pass it to requestAnimationFrame()
      var render = function () {
        requestAnimationFrame( render );

        renderer.render( scene, camera );
      };

      // Kick off the rendering process
      render();
    },

    //
    // View: Renders a 3D visualization of the given zones array to #visualization-container
    //
    render: function(zones) {

      // Remove all previously added objects from the scene, other than camera
      for (let i = scene.children.length - 1; i >= 0 ; i--) {
        let child = scene.children[ i ];

        if ( child !== camera ) { // camera is stored earlier
          scene.remove(child);
        }
      }

      // Create an array of Meshes that represent the zones
      meshes = [];
      geometry = new THREE.BoxGeometry( 1, 1, 1 );
      material = new THREE.MeshBasicMaterial( { color: 0x00c8ff } );

      // Create one cube object for each zone (even empty zones) and add them to the scene
      var numZones = zones.length;
      for (var i = 0; i < numZones; i++) {
        var cube = new THREE.Mesh( geometry, material );
        var spacing = 1.8;
        var zone = zones[i];
        var verticalScale = 0.1 + zone.count / 6;
        // var horizontalScale = 1 / (1 + Math.abs(numZones/2 - i));
        cube.scale.setX(0.2);
        cube.scale.setY(verticalScale);
        // cube.scale.setZ(horizontalScale);
        cube.scale.setZ(0.2);
        cube.position.set( (numZones/2 - i) * spacing, verticalScale/2, 0 );
        scene.add( cube );
      }
    }
  }

}) ();
