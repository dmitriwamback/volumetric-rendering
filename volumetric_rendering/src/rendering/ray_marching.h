//
//  ray_marching.h
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-10.
//

#ifndef ray_marching_h
#define ray_marching_h

class RayMarchingQuad {
public:
    std::vector<Vertex> vertices;
    
    static RayMarchingQuad Create();
    void Render(Shader shader, DeferredRenderer renderer);
private:
    uint32_t vertexArrayObject, vertexBufferObject;
};

RayMarchingQuad RayMarchingQuad::Create() {
    RayMarchingQuad quad = RayMarchingQuad();
    
    quad.vertices = {
        {{-1.0f,  1.0f,  0.0f}, { 0,  0,  1}, {0, 1}},
        {{ 1.0f,  1.0f,  0.0f}, { 0,  0,  1}, {1, 1}},
        {{-1.0f, -1.0f,  0.0f}, { 0,  0,  1}, {0, 0}},
        
        {{ 1.0f,  1.0f,  0.0f}, { 0,  0,  1}, {1, 1}},
        {{ 1.0f, -1.0f,  0.0f}, { 0,  0,  1}, {1, 0}},
        {{-1.0f, -1.0f,  0.0f}, { 0,  0,  1}, {0, 0}},
    };
    
    glGenVertexArrays(1, &quad.vertexArrayObject);
    glBindVertexArray(quad.vertexArrayObject);
    
    glGenBuffers(1, &quad.vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, quad.vertexBufferObject);
    glBufferData(GL_ARRAY_BUFFER, quad.vertices.size() * sizeof(Vertex), quad.vertices.data(), GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, vertex));
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, normal));
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, uv));
    
    return quad;
}

void RayMarchingQuad::Render(Shader shader, DeferredRenderer renderer) {
    shader.Use();
    
    
    glm::mat4 inverseProjection = glm::inverse(camera.projection);
    glm::mat4 inverseLookAt = glm::inverse(camera.lookAt);
    glm::vec3 cameraPosition = camera.position;
    
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    
    glm::vec2 screenSize = glm::vec2(width, height);
    
    shader.SetMatrix4("inverseProjection", inverseProjection);
    shader.SetMatrix4("inverseLookAt", inverseLookAt);
    shader.SetVector3("cameraPosition", cameraPosition);
    shader.SetVector2("screenSize", screenSize);
    
    glActiveTexture(GL_TEXTURE0);
    shader.SetInt("position", 0);
    glBindTexture(GL_TEXTURE_2D, renderer.position);
    
    glActiveTexture(GL_TEXTURE1);
    shader.SetInt("distanceToCamera", 1);
    glBindTexture(GL_TEXTURE_2D, renderer.distanceToCamera);
    
    glActiveTexture(GL_TEXTURE2);
    shader.SetInt("normal", 2);
    glBindTexture(GL_TEXTURE_2D, renderer.normal);
    
    glActiveTexture(GL_TEXTURE3);
    shader.SetInt("albedo", 3);
    glBindTexture(GL_TEXTURE_2D, renderer.albedo);
    
    glBindVertexArray(vertexArrayObject);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glBindVertexArray(0);
}

#endif /* ray_marching_h */
