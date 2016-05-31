var visualization = (function() {

  return {
    render: function(zones) {
      var width = $('#visualization-container').width();
      var height = $('#visualization-container').height();
      var scene = new THREE.Scene();
      var camera = new THREE.PerspectiveCamera( 75, width/height, 0.1, 1000 );
      var renderer = new THREE.WebGLRenderer({ alpha: true });
      renderer.setClearColor( 0xffffff, 0 );
      renderer.setSize( width, height );
      $('#visualization-container').empty();
      $('#visualization-container').append( renderer.domElement );

      var geometry = new THREE.BoxGeometry( 1, 1, 1 );
      var material = new THREE.MeshBasicMaterial( { color: 0x00c8ff } );
      var cube = new THREE.Mesh( geometry, material );
      scene.add( cube );

      camera.position.z = 5;

      var render = function () {
        requestAnimationFrame( render );

        cube.rotation.x += 0.1;
        cube.rotation.y += 0.1;

        renderer.render(scene, camera);
      };

      render();
    }
  }

}) ();
