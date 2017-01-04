var twgl = require("twgl.js");
require("../lib/wutils.min.js");
//require("../lib/ShaderLoader.js");

//Create a namespace for shadrs
var shadrs = {};

//Basic vertex shader
var vertSource = "attribute vec4 position; \n void main() { \n gl_Position = position; \n }"

//Create a shader viewer
shadrs.CreateViewer = function(canvasDOM, fragSource)
{
  var gl, programInfo, bufferInfo, uniforms = {};

  function render(time) {
    //twgl.resizeCanvasToDisplaySize(gl.canvas);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

    uniforms.iGlobalTime = time * 0.001;
    uniforms.time = time * 0.001;
    uniforms.iResolution = [gl.canvas.width, gl.canvas.height];

    gl.useProgram(programInfo.program);
    twgl.setBuffersAndAttributes(gl, programInfo, bufferInfo);
    twgl.setUniforms(programInfo, uniforms);
    twgl.drawBufferInfo(gl, gl.TRIANGLES, bufferInfo);
    requestAnimationFrame(render);
  }

  wutils.file.loadMultiple([fragSource], function(files, d) {
    gl = twgl.getWebGLContext(canvasDOM);

    programInfo = twgl.createProgramInfo(gl, [vertSource, files[0]]);

    var arrays = {
      position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
    };
    bufferInfo = twgl.createBufferInfoFromArrays(gl, arrays);

    render();

    /*viewer.uniforms = {
      iChannel1: twgl.createTexture(gl, {
        target: gl.TEXTURE_CUBE_MAP,
        src: [
          'images/clouds/pos-x.png',
          'images/clouds/neg-x.png',
          'images/clouds/pos-y.png',
          'images/clouds/neg-y.png',
          'images/clouds/pos-z.png',
          'images/clouds/neg-z.png',
        ],
      }),
      iChannel0: twgl.createTexture(gl, {
        mag: gl.NEAREST,
        src: 'images/normalmaps/PaperNormal.jpg'
      })
    };*/
  });

  return viewer;
}




//Expose shadrs to the global object
window.shadrs = shadrs;

console.log("Hello?");
