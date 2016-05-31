var visualization = (function() {

  return {

    //
    // View: Renders a 3D visualization of the given zones array to #visualization-container
    //
    render: function(zones) {

      // Query container element for dimensions to set our Three.js canvas to
      var width = $( '#visualization-container' ).width();
      var height = $( '#visualization-container' ).height();

      // Initialize Three.js
      var scene = new THREE.Scene();
      var camera = new THREE.PerspectiveCamera( 35, width/height, 0.1, 1000 );
      var renderer = new THREE.WebGLRenderer( { alpha: true, antialias: true } );
      renderer.setClearColor( 0xffffff, 0 );
      renderer.setSize( width, height );

      // Attach Three.js canvas to container element
      $( '#visualization-container' ).empty();
      $( '#visualization-container' ).append( renderer.domElement );

      // Create an array of Meshes that represent the zones
      var meshes = [];
      var geometry = new THREE.BoxGeometry( 1, 1, 1 );
      var material = new THREE.MeshBasicMaterial( { color: 0x00c8ff } );

      // Create one cube object for each zone (even empty zones)
      var numZones = zones.length;
      for (var i = 0; i < numZones; i++) {
        var cube = new THREE.Mesh( geometry, material );
        var spacing = 1.5;
        var zone = zones[i];
        var verticalScale = 0.1 + zone.count / 5;
        var horizontalScale = 1 / (1 + Math.abs(numZones/2 - i));
        console.log('> ', horizontalScale);
        cube.scale.setX(.2);
        cube.scale.setY(verticalScale);
        cube.scale.setZ(horizontalScale);
        cube.position.set( (numZones/2 - i) * spacing, verticalScale/2, 0 );
        scene.add( cube );
      }

      // Set camera's z position
      camera.position.z = 15;
      camera.position.y = 5;
      camera.rotation.x = -.2;

      // Define render callback animation function and pass it to requestAnimationFrame()
      var render = function () {
        requestAnimationFrame( render );

        renderer.render( scene, camera );
      };

      // Kick off the rendering process
      render();
    }
  }

}) ();
