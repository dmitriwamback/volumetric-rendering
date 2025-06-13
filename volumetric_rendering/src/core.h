//
//  core.h
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-10.
//

#include <GL/glew.h>
#include <glfw3.h>

GLFWwindow* window;

#include <fstream>
#include <sstream>
#include <vector>

#include <glm/glm.hpp>
#include <glm/mat4x4.hpp>
#include <glm/vec3.hpp>
#include <glm/vec2.hpp>
#include <glm/vec4.hpp>

#include <glm/gtc/matrix_transform.hpp>

#include "rendering/noise.h"

#include "object/vertex.h"
#include "object/shader.h"
#include "object/cube.h"

#include "object/camera.h"

#include "rendering/deferred_renderer.h"
#include "rendering/ray_marching.h"

void initialize() {
    
    glfwInit();
    
#if defined(__APPLE__)
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    
    window = glfwCreateWindow(1200, 800, "Volumetric Rendering", nullptr, nullptr);
    glfwMakeContextCurrent(window);
    
    glewExperimental = GL_TRUE;
    glewInit();
    glEnable(GL_DEPTH_TEST);
    
    Camera::Initialize();
    glfwSetCursorPosCallback(window, cursor_position_callback);
    
    Shader shader = Shader::Create("/Users/dmitriwamback/Documents/Projects/volumetric_rendering/volumetric_rendering/src/shaders/main"),
           rayMarchingShader = Shader::Create("/Users/dmitriwamback/Documents/Projects/volumetric_rendering/volumetric_rendering/src/shaders/atmospheric_clouds");
    Cube cube = Cube::Create();
    RayMarchingQuad quad = RayMarchingQuad::Create();
    
    DeferredRenderer renderer = DeferredRenderer::Create();
    
    while (!glfwWindowShouldClose(window)) {
        
        
        glm::vec4 movement = glm::vec4(0.0f);
        
        movement.z = glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS ?  0.05f : 0;
        movement.w = glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS ? -0.05f : 0;
        movement.x = glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS ?  0.05f : 0;
        movement.y = glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS ? -0.05f : 0;
        
        if (glfwGetKey(window, GLFW_KEY_E) == GLFW_PRESS) quad.GenerateNoiseTexture();
                
        camera.Update(movement);
        std::cout << camera.position.x << " " << camera.position.y << " " << camera.position.z << '\n';
        
        renderer.Bind();
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        shader.Use();
        shader.SetVector3("cameraPosition", camera.position);
        shader.SetMatrix4("projection", camera.projection);
        shader.SetMatrix4("lookAt", camera.lookAt);
        cube.Render(shader);
        renderer.Unbind();
        
        glClearColor(0.3, 0.3, 0.3, 0.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        quad.Render(rayMarchingShader, renderer);
        
        glfwPollEvents();
        glfwSwapBuffers(window);
    }
    
    glfwDestroyWindow(window);
}
