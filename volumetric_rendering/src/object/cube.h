//
//  cube.h
//  volumetric_rendering
//
//  Created by Dmitri Wamback on 2025-06-10.
//

#ifndef cube_h
#define cube_h

class Cube {
public:
    std::vector<Vertex> vertices;
    static Cube Create();
    void Render(Shader shader);
    
    glm::vec3 position, scale, rotation;
    
    glm::mat4 CreateModelMatrix();
private:
    uint32_t vertexArrayObject, vertexBufferObject;
};

Cube Cube::Create() {
    
    Cube cube = Cube();
    
    cube.vertices = {
        {{-0.5f, -0.5f,  0.5f}, { 0,  0,  1}, {0, 0}},
        {{ 0.5f, -0.5f,  0.5f}, { 0,  0,  1}, {1, 0}},
        {{ 0.5f,  0.5f,  0.5f}, { 0,  0,  1}, {1, 1}},
        {{ 0.5f,  0.5f,  0.5f}, { 0,  0,  1}, {1, 1}},
        {{-0.5f,  0.5f,  0.5f}, { 0,  0,  1}, {0, 1}},
        {{-0.5f, -0.5f,  0.5f}, { 0,  0,  1}, {0, 0}},

        // Back face
        {{ 0.5f, -0.5f, -0.5f}, { 0,  0, -1}, {0, 0}},
        {{-0.5f, -0.5f, -0.5f}, { 0,  0, -1}, {1, 0}},
        {{-0.5f,  0.5f, -0.5f}, { 0,  0, -1}, {1, 1}},
        {{-0.5f,  0.5f, -0.5f}, { 0,  0, -1}, {1, 1}},
        {{ 0.5f,  0.5f, -0.5f}, { 0,  0, -1}, {0, 1}},
        {{ 0.5f, -0.5f, -0.5f}, { 0,  0, -1}, {0, 0}},

        // Right face
        {{ 0.5f, -0.5f,  0.5f}, { 1,  0,  0}, {0, 0}},
        {{ 0.5f, -0.5f, -0.5f}, { 1,  0,  0}, {1, 0}},
        {{ 0.5f,  0.5f, -0.5f}, { 1,  0,  0}, {1, 1}},
        {{ 0.5f,  0.5f, -0.5f}, { 1,  0,  0}, {1, 1}},
        {{ 0.5f,  0.5f,  0.5f}, { 1,  0,  0}, {0, 1}},
        {{ 0.5f, -0.5f,  0.5f}, { 1,  0,  0}, {0, 0}},

        // Left face
        {{-0.5f, -0.5f, -0.5f}, {-1,  0,  0}, {0, 0}},
        {{-0.5f, -0.5f,  0.5f}, {-1,  0,  0}, {1, 0}},
        {{-0.5f,  0.5f,  0.5f}, {-1,  0,  0}, {1, 1}},
        {{-0.5f,  0.5f,  0.5f}, {-1,  0,  0}, {1, 1}},
        {{-0.5f,  0.5f, -0.5f}, {-1,  0,  0}, {0, 1}},
        {{-0.5f, -0.5f, -0.5f}, {-1,  0,  0}, {0, 0}},

        // Top face
        {{-0.5f,  0.5f,  0.5f}, { 0,  1,  0}, {0, 0}},
        {{ 0.5f,  0.5f,  0.5f}, { 0,  1,  0}, {1, 0}},
        {{ 0.5f,  0.5f, -0.5f}, { 0,  1,  0}, {1, 1}},
        {{ 0.5f,  0.5f, -0.5f}, { 0,  1,  0}, {1, 1}},
        {{-0.5f,  0.5f, -0.5f}, { 0,  1,  0}, {0, 1}},
        {{-0.5f,  0.5f,  0.5f}, { 0,  1,  0}, {0, 0}},

        // Bottom face
        {{-0.5f, -0.5f, -0.5f}, { 0, -1,  0}, {0, 0}},
        {{ 0.5f, -0.5f, -0.5f}, { 0, -1,  0}, {1, 0}},
        {{ 0.5f, -0.5f,  0.5f}, { 0, -1,  0}, {1, 1}},
        {{ 0.5f, -0.5f,  0.5f}, { 0, -1,  0}, {1, 1}},
        {{-0.5f, -0.5f,  0.5f}, { 0, -1,  0}, {0, 1}},
        {{-0.5f, -0.5f, -0.5f}, { 0, -1,  0}, {0, 0}},
    };
    
    cube.scale = glm::vec3(1.0f);
    cube.rotation = glm::vec3(0.0f);
    cube.position = glm::vec3(0.0f);
    
    glGenVertexArrays(1, &cube.vertexArrayObject);
    glBindVertexArray(cube.vertexArrayObject);
    
    glGenBuffers(1, &cube.vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, cube.vertexBufferObject);
    glBufferData(GL_ARRAY_BUFFER, cube.vertices.size() * sizeof(Vertex), cube.vertices.data(), GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, vertex));
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, normal));
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, uv));
    
    return cube;
}

void Cube::Render(Shader shader) {
    
    shader.Use();
    
    glm::mat4 model = CreateModelMatrix();
        
    glBindVertexArray(vertexArrayObject);

    shader.SetMatrix4("model", model);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    glBindVertexArray(0);
}

glm::mat4 Cube::CreateModelMatrix() {
    
    glm::mat4 model = glm::mat4(1.0f);
    glm::mat4 translationMatrix = glm::mat4(1.0f);
    translationMatrix = glm::translate(translationMatrix, position);
    
    glm::mat4 scaleMatrix = glm::mat4(1.0f);
    scaleMatrix = glm::scale(scaleMatrix, scale);
    
    glm::mat4 rotationMatrix = glm::rotate(glm::mat4(1.0f), glm::radians(rotation.x), glm::vec3(1, 0, 0)) *
                               glm::rotate(glm::mat4(1.0f), glm::radians(rotation.y), glm::vec3(0, 1, 0)) *
                               glm::rotate(glm::mat4(1.0f), glm::radians(rotation.z), glm::vec3(0, 0, 1));
    
    model = translationMatrix * rotationMatrix * scaleMatrix;
    
    return model;
}

#endif /* cube_h */
