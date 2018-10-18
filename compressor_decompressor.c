#define _CRT_SECURE_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

// ------------------------------------------------------------------------------------------

typedef struct huffman_node {
    unsigned char key;
    int weight;
    struct huffman_node * left_child;
    struct huffman_node * right_child;
} huffman_node;

huffman_node * huffman_node_create_external_node(int n) {
    huffman_node * node = (huffman_node *)malloc(sizeof(huffman_node));
    node->key = (unsigned char)n;
    node->weight = 0;
    node->left_child = NULL;
    node->right_child = NULL;
    return node;
}

huffman_node * huffman_node_create_internal_node(huffman_node * left_child, huffman_node * right_child) {
    huffman_node * node = (huffman_node *)malloc(sizeof(huffman_node));
    node->key = (unsigned char)0;
    node->weight = left_child->weight + right_child->weight;
    node->left_child = left_child;
    node->right_child = right_child;
    return node;
}

void huffman_node_destory(huffman_node * node) {
    if (node) {
        free(node);
    }
}

// ------------------------------------------------------------------------------------------

#define  in_heap(n, i)          ( ( ( -1 ) < ( i ) ) && ( ( i ) < ( n ) ) ) // �ж�q[i]�Ƿ�Ϸ�
#define  parent(i)              ( ( i - 1 ) >> 1 ) // q[i]�ĸ��ڵ㣨floor((i-1)/2)��i����������
#define  last_internal(n)       parent( n - 1 ) // ���һ���ڲ��ڵ㣨��ĩ�ڵ�ĸ��ף�
#define  lchild(i)              ( 1 + ( ( i ) << 1 ) ) // q[i]������
#define  rchild(i)              ( ( 1 + ( i ) ) << 1 ) // q[i]���Һ���
#define  parent_valid(i)        ( 0 < i ) // �ж�q[i]�Ƿ��и���
#define  lchild_valid(n, i)     in_heap( n, lchild( i ) ) // �ж�q[i]�Ƿ���һ�����󣩺���
#define  rchild_valid(n, i)     in_heap( n, rchild( i ) ) // �ж�q[i]�Ƿ�����������
#define  bigger(q, i, j)        ( q->nodes[j]->weight < q->nodes[i]->weight ? j : i ) // ȡ���ߣ���ʱǰ�����ȣ�
#define  properparent(q, n, i) /* ���ӣ����ࣩ�����еĴ��� */ \
            ( rchild_valid(n, i) ? bigger( q, bigger( q, i, lchild(i) ), rchild(i) ) : \
            ( lchild_valid(n, i) ? bigger( q, i, lchild(i) ) : i \
            ) \
            ) // ���ʱ���ڵ����ȣ���˿ɱ��ⲻ��Ҫ�Ľ���

typedef struct priority_queue {
    int size;
    huffman_node * nodes[256];
} pq;

pq * pq_create() {
    pq * q = (pq *)malloc(sizeof(pq));
    for (int i = 0; i < 256; ++i) {
        q->nodes[i] = NULL;
    }
    q->size = 0;
    return q;
}

void pq_destory(pq * q) {
    for (int i = 0; i < q->size; ++i) {
        huffman_node_destory(q->nodes[i]);
    }
    free(q);
}

huffman_node * pq_getmax(pq * q) {
    return q->nodes[0];
}

// �������еĵ� i ������ʵʩ���˲�����i < size�������������յִ��λ��
int pq_percolate_up(pq * q, int i) {
    while (0 < i) { // ֻҪ i �и��ף���δ�ִ�Ѷ�������
        int j = parent(i); // �� i ֮������ j
        if (q->nodes[j]->weight < q->nodes[i]->weight) {
            break; // һ����ǰ���Ӳ������������������
        }
        // swap
        huffman_node * t = q->nodes[i];
        q->nodes[i] = q->nodes[j];
        q->nodes[j] = t;
        i = j; // ���򣬸��ӽ���λ�ã�������������һ��
    } //while
    return i; //�����������յִ��λ��
}

// ������ǰ n�� �����еĵ� i ��ʵʩ���ˣ�i < n
int pq_percolate_down(pq * q, int n, int i) {
    int j; // i���䣨���������������У���Ϊ����
    while (i != (j = properparent(q, n, i))) { // ֻҪi��j����
        // swap
        huffman_node * t = q->nodes[i];
        q->nodes[i] = q->nodes[j];
        q->nodes[j] = t;
        i = j;
    } // ���߻�λ�������������½����i
    return i; // �������˵ִ��λ�ã���i��j��
}

void pq_heapify(pq * q, int n) { // Floyd�����㷨��O(n)ʱ��
    for (int i = last_internal(n); in_heap(n, i); i--) { // �Ե׶��ϣ�����
        pq_percolate_down(q, n, i); // ���˸��ڲ��ڵ�
    }
}

void pq_insert(pq * q, huffman_node * node) { // ������������ȫ�������
    // ���Ƚ��´�����������ĩβ
    q->nodes[q->size] = node;
    q->size++;
    // �ٶԸô���ʵʩ���˵���
    pq_percolate_up(q, q->size - 1); 
}

huffman_node * pq_delmax(pq * q) { // ɾ���ǿ���ȫ����������ȼ���ߵĴ���
    huffman_node * max = q->nodes[0];
    q->nodes[0] = q->nodes[--(q->size)]; // ժ���Ѷ����״���������֮��ĩ����
    pq_percolate_down(q, q->size, 0); // ���¶Ѷ�ʵʩ����
    return max; // ���ش�ǰ���ݵ�����������Ҫ�ⲿ�ͷ�
}

pq * char_statistics(unsigned char * file_name, int * byte_count) {
    *byte_count = 0;
    // ��ʼ�� pq
    pq * q = pq_create();
    huffman_node * nodes[256];
    for (int i = 0; i < 256; ++i) {
        nodes[i] = huffman_node_create_external_node(i);
    }
    // ���ļ����ж�ȡ
    FILE * file_stream = NULL;
    if ((file_stream = fopen(file_name, "rb")) == NULL) {
        pq_destory(q);
        for (int i = 0; i < 256; ++i) {
            huffman_node_destory(nodes[i]);
        }
        return NULL;
    }
    int c = 0;
    while ((c = fgetc(file_stream)) != EOF) {
        nodes[(unsigned char)c]->weight++;
        ++(*byte_count);
    }
    fclose(file_stream);
    // ����
    for (int i = 0; i < 256; ++i) {
        pq_insert(q, nodes[i]);
    }
    return q;
}

typedef huffman_node huffman_forest;

huffman_forest * huffman_forest_create(pq * q) {
    if (!q || q->size == 0) {
        return NULL;
    }
    while (q->size > 1) {
        huffman_node * first = pq_delmax(q);
        huffman_node * second = pq_delmax(q);
        huffman_node * internal_node = huffman_node_create_internal_node(first, second);
        pq_insert(q, internal_node);
    }
    return pq_delmax(q);
}

void huffman_forest_destory(huffman_forest * forest) {
    if (!forest) {
        return;
    }
    if (forest->left_child) {
        huffman_forest_destory(forest->left_child);
    }
    if (forest->right_child) {
        huffman_forest_destory(forest->right_child);
    }
    huffman_node_destory(forest);
}

// ------------------------------------------------------------------------------------------

typedef struct mapper {
    int bit_length;
    unsigned char bits[256];
    int weight;
} mapper;

mapper * mapper_init() {
    mapper * mappers = (mapper *)malloc(sizeof(mapper) * 256);
    for (int i = 0; i < 256; ++i) {
        mappers[i].bit_length = 0;
        mappers[i].weight = 0;
    }
    return mappers;
}

void mapper_destory(mapper * mappers) {
    if (mappers) {
        free(mappers);
    }
}

void mapper_set(mapper * mappers, unsigned char order, int bit_length, unsigned char * bits, int weight) {
    mappers[order].bit_length = bit_length;
    mappers[order].weight = weight;
    for (int i = 0; i < bit_length; ++i) {
        mappers[order].bits[i] = bits[i];
    }
}

void _mapper_set_all(mapper * mappers, huffman_node * forest, int depth, unsigned char * bits) {
    if (!(forest->left_child) && !(forest->right_child)) {
        mapper_set(mappers, forest->key, depth + 1, bits, forest->weight);
        return;
    }
    if (forest->left_child) {
        bits[depth + 1] = 0;
        _mapper_set_all(mappers, forest->left_child, depth + 1, bits);
    }
    if (forest->right_child) {
        bits[depth + 1] = 1;
        _mapper_set_all(mappers, forest->right_child, depth + 1, bits);
    }
}

void mapper_set_all(mapper * mappers, huffman_node * forest) {
    unsigned char bits[256] = { 0, }; // �������
    _mapper_set_all(mappers, forest, 0, bits);
}

// ------------------------------------------------------------------------------------------

typedef struct huffman_buffer {
    int current_bit_size;
    int byte_capacity;
    unsigned char * buffer;
} huffman_buffer;

huffman_buffer * huffman_buffer_create(int max_byte_count) {
    huffman_buffer * buffer = (huffman_buffer *)malloc(sizeof(huffman_buffer));
    buffer->current_bit_size = 0;
    buffer->byte_capacity = max_byte_count;
    //! ��ʼ��Ϊ0
    buffer->buffer = (unsigned char *)malloc(max_byte_count * sizeof(unsigned char));
    memset(buffer->buffer, 0, max_byte_count);
    return buffer;
}

void huffman_buffer_destory(huffman_buffer * buffer) {
    if (buffer) {
        if (buffer->buffer) {
            free(buffer->buffer);
        }
        free(buffer);
    }
}

void huffman_buffer_insert(huffman_buffer * buffer, int bit_count, unsigned char * bits) {
    for (int i = 0; i < bit_count; ++i) {
        if (bits[i] == 1) {
            buffer->buffer[buffer->current_bit_size / 8] |= (0x1 << (buffer->current_bit_size % 8));
        }
        buffer->current_bit_size++;
    }
}

// ------------------------------------------------------------------------------------------

int get_compressed_size(huffman_buffer * data_buffer) {
    return data_buffer->current_bit_size / 8 + (data_buffer->current_bit_size % 8 ? 1 : 0);
}

void compress_into_buffer(char * file_name, huffman_buffer * buffer, mapper * mappers) {
    FILE * file_stream = NULL;
    if ((file_stream = fopen(file_name, "rb")) == NULL) {
        return;
    }
    int c = 0;
    while ((c = fgetc(file_stream)) != EOF) {
        huffman_buffer_insert(buffer, mappers[c].bit_length, mappers[c].bits);
    }
    fclose(file_stream);
    return;
}

#define DECODE_INFO_BUFFER_SIZE (2 * sizeof(int) + 16 + sizeof(int) * 256)

void save_encode_info_into_buffer(huffman_buffer * buffer, int decompressed_size, int compressed_size, char * password, mapper * mappers ) {
    ((int *)(buffer->buffer))[0] = decompressed_size;
    ((int *)(buffer->buffer))[1] = compressed_size;
    char * password_offset = (char *)((int *)(buffer->buffer) + 2);
    for (int i = 0; i < 16; ++i) {
        password_offset[i] = password[i];
    }
    char * data_offset = password_offset + 16;
    for (int i = 0; i < 256; ++i) {
        ((int *)data_offset)[i] = mappers[i].weight;
    }
    buffer->current_bit_size += (DECODE_INFO_BUFFER_SIZE) << 3;
}

void write_into_file(huffman_buffer * info_buffer, huffman_buffer * data_buffer, char * file_name) {
    FILE * file_stream = NULL;
    if ((file_stream = fopen(file_name, "wb")) == NULL) {
        return;
    }
    if (info_buffer) {
        int count = info_buffer->current_bit_size / 8 + (info_buffer->current_bit_size % 8 ? 1 : 0);
        for (int i = 0; i < count; ++i) {
            fputc(info_buffer->buffer[i], file_stream);
        }
    }
    if (data_buffer) {
        int count = data_buffer->current_bit_size / 8 + (data_buffer->current_bit_size % 8 ? 1 : 0);
        for (int i = 0; i < count; ++i) {
            fputc(data_buffer->buffer[i], file_stream);
        }
    }
    fclose(file_stream);
}

// ------------------------------------------------------------------------------------------

// ����ָ��ָ����Ϊ����ֵ
int read_from_file(huffman_buffer ** info_buffer, huffman_buffer ** data_buffer, char * file_name) {
    // ���ļ����ж�ȡ
    FILE * file_stream = NULL;
    if ((file_stream = fopen(file_name, "rb")) == NULL) {
        return 0;
    }
    if (info_buffer) {
        *info_buffer = huffman_buffer_create(DECODE_INFO_BUFFER_SIZE);
        for (int i = 0; i < DECODE_INFO_BUFFER_SIZE; ++i) {
            (*info_buffer)->buffer[i] = (unsigned char)fgetc(file_stream);
        }
    }
    if (data_buffer) {
        int size = ((int *)((*info_buffer)->buffer))[1];
        *data_buffer = huffman_buffer_create(size);
        for (int i = 0; i < size; ++i) {
            (*data_buffer)->buffer[i] = (unsigned char)fgetc(file_stream);
        }
    }
    fclose(file_stream);
    return 1;
}

pq * rebuild_pq(huffman_buffer * info_buffer) {
    // ��ʼ�� pq
    pq * q = pq_create();
    huffman_node * nodes[256];
    char * data_offset = info_buffer->buffer + 2 * sizeof(int) + 16;
    for (int i = 0; i < 256; ++i) {
        nodes[i] = huffman_node_create_external_node(i);
        nodes[i]->weight = ((int *)data_offset)[i];
    }
    // ����
    for (int i = 0; i < 256; ++i) {
        pq_insert(q, nodes[i]);
    }
    return q;
}

unsigned char huffman_buffer_get_next_bit(huffman_buffer * data_buffer) {
    unsigned char ret = !!(data_buffer->buffer[data_buffer->current_bit_size / 8]
        & (0x1 << (data_buffer->current_bit_size % 8)));
    data_buffer->current_bit_size++;
    return ret;
}

unsigned char huffman_buffer_get_next_byte(huffman_buffer * data_buffer, huffman_node * forest) {
    // ע�⣬�˿�huffman�����ǹ�������0��1�����ڵ������������ӣ����ڵ��Һ��ӻ����������Һ��ӣ�����һ��
    huffman_node * current = huffman_buffer_get_next_bit(data_buffer) ? forest->right_child : forest;
    while (current->left_child || current->right_child) {
        unsigned char bit = huffman_buffer_get_next_bit(data_buffer);
        current = bit == 0 ? current->left_child : current->right_child;
    }
    return current->key;
}

huffman_buffer * decompress_into_buffer(huffman_buffer * info_buffer, huffman_buffer * data_buffer, huffman_node * forest) {
    int decompressed_size = ((int *)(info_buffer->buffer))[0];
    huffman_buffer * decompressed_buffer = huffman_buffer_create(decompressed_size);
    for (int i = 0; i < decompressed_size; ++i) {
        unsigned char c = huffman_buffer_get_next_byte(data_buffer, forest);
        decompressed_buffer->buffer[i] = c;
        decompressed_buffer->current_bit_size = (i + 1) << 3;
    }
    return decompressed_buffer;
}

// ------------------------------------------------------------------------------------------

extern void calc_md5(int block_size, char * datablock, char * dest_hash);

char * md5(char * password) {
    int len = strlen(password);
    char * md5_code = (char *)malloc(16);
    calc_md5(len, password, md5_code);
    return md5_code; // ��Ҫ�ⲿ�ͷ�
}

int password_is_valid(char * input_password, huffman_buffer * info_buffer) {
    char * md5_stored = info_buffer->buffer + 2 * sizeof(int);
    char * md5_input = md5(input_password);
    for (int i = 0; i < 16; ++i) {
        if (md5_input[i] != md5_stored[i]) {
            return 0;
        }
    }
    free(md5_input);
    return 1;
}

// ------------------------------------------------------------------------------------------

void compress(char * file_name, char * password) {
    char * md5_code = md5(password ? password : "");
    int decompressed_size = 0;
    pq * q = char_statistics(file_name, &decompressed_size);
    if (!q) {
        printf("[ FAILED ]: No such file named [ %s ] ...\n", file_name);
        return;
    }
    printf("[ INFO ]: Compressing ...\n");
    huffman_forest * forest = huffman_forest_create(q);
    mapper * mappers = mapper_init();
    mapper_set_all(mappers, forest);

    huffman_buffer * data_buffer = huffman_buffer_create(decompressed_size * 2); // ����ֵ emmmmm
    compress_into_buffer(file_name, data_buffer, mappers);
    int compressed_size = get_compressed_size(data_buffer);
    huffman_buffer * info_buffer = huffman_buffer_create(DECODE_INFO_BUFFER_SIZE);
    save_encode_info_into_buffer(info_buffer, decompressed_size, compressed_size, md5_code, mappers);
    
    char * compressed_file_name = (char *)malloc(strlen(file_name) + 4 + 1);
    strcpy(compressed_file_name, file_name);
    strcat(compressed_file_name, ".tql");
    write_into_file(info_buffer, data_buffer, compressed_file_name);
    printf("[ INFO ]: File [ %s ] was compressed into [ %s ] successfully...\n", file_name, compressed_file_name);

    free(md5_code);
    pq_destory(q);
    huffman_forest_destory(forest);
    mapper_destory(mappers);
    huffman_buffer_destory(data_buffer);
    huffman_buffer_destory(info_buffer);
    free(compressed_file_name);
}

void decompress(char * file_name, char * password) {
    huffman_buffer * data_buffer = NULL, *info_buffer = NULL;
    if (!read_from_file(&info_buffer, &data_buffer, file_name)) {
        printf("[ FAILED ]: No such file named [ %s ] ...\n", file_name);
        return;
    }
    if (!password_is_valid(password ? password : "", info_buffer)) {
        printf("[ FAILED ]: You have NO permission to decompress the file.\n");
        huffman_buffer_destory(data_buffer);
        huffman_buffer_destory(info_buffer);
        return;
    }
    else {
        printf("[ INFO ]: Decompressing ...\n");
    }

    pq * q = rebuild_pq(info_buffer);
    huffman_forest * forest = huffman_forest_create(q);
    huffman_buffer * decompressed_buffer = decompress_into_buffer(info_buffer, data_buffer, forest);
    mapper * mappers = mapper_init();
    mapper_set_all(mappers, forest);

    char * decompressed_file_name = (char *)malloc(strlen(file_name) + 1);
    strcpy(decompressed_file_name, file_name);
    decompressed_file_name[strlen(file_name) - 4] = 0;

    write_into_file(NULL, decompressed_buffer, decompressed_file_name);
    printf("[ INFO ]: File [ %s ] was decompressed into [ %s ] successfully...\n", file_name, decompressed_file_name);

    pq_destory(q);
    huffman_forest_destory(forest);
    huffman_buffer_destory(decompressed_buffer);
    mapper_destory(mappers);
    free(decompressed_file_name);
}

void usage() {
    printf("Usage:\n");
    printf("  compress filename\n");    
    printf("  decompress filename\n");
    printf("  compress filename [ -p password ]\n");
    printf("  decompress filename [ -p password ]\n");
}

// ------------------------------------------------------------------------------------------

int main(int argc, char * argv[]) {
    if (argc == 3) {
        if (strcmp(argv[1], "compress") == 0) {
            compress(argv[2], NULL);
            return 0;
        }
        if (strcmp(argv[1], "decompress") == 0) {
            decompress(argv[2], NULL);
            return 0;
        }
    }
    if (argc == 5) {
        if (strcmp(argv[1], "compress") == 0 && strcmp(argv[3], "-p") == 0) {
            compress(argv[2], argv[4]);
            return 0;
        }
        if (strcmp(argv[1], "decompress") == 0 && strcmp(argv[3], "-p") == 0) {
            decompress(argv[2], argv[4]);
            return 0;
        }
    }
    usage();
    return 0;
}
