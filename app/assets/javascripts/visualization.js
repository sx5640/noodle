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
      var camera = new THREE.PerspectiveCamera( 75, width/height, 0.1, 1000 );
      var renderer = new THREE.WebGLRenderer( { alpha: true } );
      renderer.setClearColor( 0xffffff, 0 );
      renderer.setSize( width, height );

      // Attach Three.js canvas to container element
      $( '#visualization-container' ).replaceWith( renderer.domElement );

      // Create an array of geometries that represent the zones
      var geometry = new THREE.BoxGeometry( 1, 1, 1 );
      var material = new THREE.MeshBasicMaterial( { color: 0x00c8ff } );
      var cube = new THREE.Mesh( geometry, material );
      scene.add( cube );

      // Set camera's z position
      camera.position.z = 5;

      // Define render callback animation function and pass it to requestAnimationFrame()
      var render = function () {
        requestAnimationFrame( render );

        cube.rotation.x += 0.1;
        cube.rotation.y += 0.1;

        renderer.render( scene, camera );
      };

      // Kick off the rendering process
      render();
    }
  }

}) ();
