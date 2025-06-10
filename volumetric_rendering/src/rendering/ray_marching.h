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
    uint32_t vertexArrayObject, vertexBufferObject, noiseBoxTexture;
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
    
    int size = 128;
    
    std::vector<float> noiseValues(size * size * size);
    
    srand(static_cast<unsigned int>(std::time(nullptr)));
    float seed = rand()%10000000;
    
    for (int x = 0; x < size; x++) {
        for (int y = 0; y < size; y++) {
            for (int z = 0; z < size; z++) {
                noiseValues[x + y * size + z * size * size] = noiseLayer((x + seed)*0.00843, (y + seed)*0.00843, 1.5f, 0.7f, 20, (z + seed)*0.00843) * 0.5f + 0.5f;
            }
        }
    }
    
    glGenTextures(1, &quad.noiseBoxTexture);
    glBindTexture(GL_TEXTURE_3D, quad.noiseBoxTexture);
    glTexImage3D(GL_TEXTURE_3D, 0, GL_R32F, size, size, size, 0, GL_RED, GL_FLOAT, noiseValues.data());
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    
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
    
    glActiveTexture(GL_TEXTURE4);
    shader.SetInt("noiseTexture", 4);
    glBindTexture(GL_TEXTURE_3D, noiseBoxTexture);
    
    glBindVertexArray(vertexArrayObject);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    glBindVertexArray(0);
}

#endif /* ray_marching_h */
