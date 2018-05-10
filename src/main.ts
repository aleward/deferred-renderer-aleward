import {vec3, vec2, mat4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Square from './geometry/Square';
import Mesh from './geometry/Mesh';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import {readTextFile} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Texture from './rendering/gl/Texture';
import PostProcess from './rendering/gl/PostProcess'

// Define an object with application parameters and button callbacks
const controls = {
  'Turn 1 On': false,
  'Focal Depth': 25,
  'Turn 2 On': true,
  'X Velocity': 1.0,
  'Y Velocity': 0.0,
  'Z Velocity': 0.0,
  'Amount': 0.77,
  'Turn 3 On': false
};

let square: Square;

// TODO: replace with your scene's stuff

let obj0: string;
let mesh0: Mesh;

let tex0: Texture;


var timer = {
  deltaTime: 0.0,
  startTime: 0.0,
  currentTime: 0.0,
  updateTime: function() {
    var t = Date.now();
    t = (t - timer.startTime) * 0.001;
    timer.deltaTime = t - timer.currentTime;
    timer.currentTime = t;
  },
}


function loadOBJText() {
  obj0 = readTextFile('./src/resources/obj/wahoo.obj')
}


function loadScene() {
  square && square.destroy();
  mesh0 && mesh0.destroy();

  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();

  mesh0 = new Mesh(obj0, vec3.fromValues(0, 0, 0));
  mesh0.create();
  console.log(mesh0.positions.length);

  tex0 = new Texture('./src/resources/textures/wahoo.bmp')
}


function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  var post1folder = gui.addFolder('Post Process 1: Focal Point');
  var post1on = post1folder.add(controls, 'Turn 1 On');
  var slider = post1folder.add(controls, 'Focal Depth', 10, 100);

  var post2folder = gui.addFolder('Post Process 2: Motion Blur');
  var post2on = post2folder.add(controls, 'Turn 2 On');
  var xVel = post2folder.add(controls, 'X Velocity');
  var yVel = post2folder.add(controls, 'Y Velocity');
  var zVel = post2folder.add(controls, 'Z Velocity');

  var post3folder = gui.addFolder('Post Process 3: Bloom');
  var post3on = post3folder.add(controls, 'Turn 3 On');
  var slider2 = post3folder.add(controls, 'Amount', 0.0, 1.0);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 9, 25), vec3.fromValues(0, 9, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0, 0, 0, 1);
  gl.enable(gl.DEPTH_TEST);

  // let currentVelocity = vec3.fromValues(1, 0, 0);
  let userVelocity = vec3.fromValues(1, 0, 0);

  // POST PROCESS SETUP
  let post1Eight = new PostProcess(new Shader(gl.FRAGMENT_SHADER, require('./shaders/examplePost-frag.glsl')));
  post1Eight.setDepth(25.0);
  let post2Eight = new PostProcess(new Shader(gl.FRAGMENT_SHADER, require('./shaders/examplePost2-frag.glsl')));
  post2Eight.setVelocity(userVelocity);
  let post3ThirtyTwo = new PostProcess(new Shader(gl.FRAGMENT_SHADER, require('./shaders/examplePost3-frag.glsl')));
  post3ThirtyTwo.setBloom(0.77);

  var currentOps = [false, true];
  var eightBitPasses = [post1Eight, post2Eight];

  renderer.add8BitPass(post2Eight);
  // renderer.add32BitPass(post3ThirtyTwo);

  const standardDeferred = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/standard-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/standard-frag.glsl')),
    ]);

  standardDeferred.setupTexUnits(["tex_Color"]);

  standardDeferred.setVelocity(userVelocity);

  function check8Bit(num: number, b: boolean) {
    renderer.remove8BitPasses();
    currentOps[num] = b;

    for (let i = 0; i < currentOps.length; i++) {
      if (currentOps[i]) {
        renderer.add8BitPass(eightBitPasses[i]);
      }
    }
  }

  let viewProj = mat4.create();
  let placeHolder = mat4.create();
  mat4.multiply(placeHolder, camera.projectionMatrix, camera.viewMatrix);

  function tick() {
    viewProj = placeHolder;
    mat4.multiply(placeHolder, camera.projectionMatrix, camera.viewMatrix);
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    timer.updateTime();
    standardDeferred.setTime(timer.currentTime);
    renderer.updateTime(timer.deltaTime, timer.currentTime);
    renderer.updateDimensions(vec2.fromValues(window.innerWidth, window.innerHeight));

    slider.onChange(function(value: number) {
      post1Eight.setDepth(value);
    })
    slider2.onChange(function(value: number) {
      post3ThirtyTwo.setBloom(value);
    })

    xVel.onChange(function(value: number) {
      userVelocity[0] = value;
      if (currentOps[1]) {
        post2Eight.setVelocity(userVelocity);
        standardDeferred.setVelocity(userVelocity);
      }
    })
    yVel.onChange(function(value: number) {
      userVelocity[1] = value;
      if (currentOps[1]) {
        post2Eight.setVelocity(userVelocity);
        standardDeferred.setVelocity(userVelocity);
      }
    })
    zVel.onChange(function(value: number) {
      userVelocity[2] = value;
      if (currentOps[1]) {
        post2Eight.setVelocity(userVelocity);
        standardDeferred.setVelocity(userVelocity);
      }
    })

    // Testing which post process shaders to use:
    post1on.onChange(function(value: boolean) {
      check8Bit(0, value);
    })
    post2on.onChange(function(value: boolean) {
      if (value) {
        post2Eight.setVelocity(userVelocity);
        standardDeferred.setVelocity(userVelocity);
      } else {
        post2Eight.setVelocity(vec3.fromValues(0.0, 0.0, 0.0));
        standardDeferred.setVelocity(vec3.fromValues(0.0, 0.0, 0.0));
      }
      check8Bit(1, value);
    })
    post3on.onChange(function(value: boolean) {
      renderer.remove32BitPasses();
      if (value) {
        renderer.add32BitPass(post3ThirtyTwo);
      }
    })

    standardDeferred.bindTexToUnit("tex_Color", tex0, 0);

    renderer.clear();
    renderer.clearGB();

    // TODO: pass any arguments you may need for shader passes
    // forward render mesh info into gbuffers
    renderer.renderToGBuffer(camera, standardDeferred, [mesh0], viewProj);
    // render from gbuffers into 32-bit color buffer
    renderer.renderFromGBuffer(camera);
    // apply 32-bit post and tonemap from 32-bit color to 8-bit color
    renderer.renderPostProcessHDR();
    // apply 8-bit post and draw
    renderer.renderPostProcessLDR();
    
    stats.end();
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}


function setup() {
  timer.startTime = Date.now();
  loadOBJText();
  main();
}

setup();
