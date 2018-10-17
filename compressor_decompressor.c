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

#define  in_heap(n, i)          ( ( ( -1 ) < ( i ) ) && ( ( i ) < ( n ) ) ) // 判断q[i]是否合法
#define  parent(i)              ( ( i - 1 ) >> 1 ) // q[i]的父节点（floor((i-1)/2)，i无论正负）
#define  last_internal(n)       parent( n - 1 ) // 最后一个内部节点（即末节点的父亲）
#define  lchild(i)              ( 1 + ( ( i ) << 1 ) ) // q[i]的左孩子
#define  rchild(i)              ( ( 1 + ( i ) ) << 1 ) // q[i]的右孩子
#define  parent_valid(i)        ( 0 < i ) // 判断q[i]是否有父亲
#define  lchild_valid(n, i)     in_heap( n, lchild( i ) ) // 判断q[i]是否有一个（左）孩子
#define  rchild_valid(n, i)     in_heap( n, rchild( i ) ) // 判断q[i]是否有两个孩子
#define  bigger(q, i, j)        ( q->nodes[j]->weight < q->nodes[i]->weight ? j : i ) // 取大者（等时前者优先）
#define  properparent(q, n, i) /* 父子（至多）三者中的大者 */ \
            ( rchild_valid(n, i) ? bigger( q, bigger( q, i, lchild(i) ), rchild(i) ) : \
            ( lchild_valid(n, i) ? bigger( q, i, lchild(i) ) : i \
            ) \
            ) // 相等时父节点优先，如此可避免不必要的交换

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

// 对向量中的第 i 个词条实施上滤操作，i < size，返回上滤最终抵达的位置
int pq_percolate_up(pq * q, int i) {
    while (0 < i) { // 只要 i 有父亲（尚未抵达堆顶），则
        int j = parent(i); // 将 i 之父记作 j
        if (q->nodes[j]->weight < q->nodes[i]->weight) {
            break; // 一旦当前父子不再逆序，上滤旋即完成
        }
        // swap
        huffman_node * t = q->nodes[i];
        q->nodes[i] = q->nodes[j];
        q->nodes[j] = t;
        i = j; // 否则，父子交换位置，并继续考查上一层
    } //while
    return i; //返回上滤最终抵达的位置
}

// 对向量前 n个 词条中的第 i 个实施下滤，i < n
int pq_percolate_down(pq * q, int n, int i) {
    int j; // i及其（至多两个）孩子中，堪为父者
    while (i != (j = properparent(q, n, i))) { // 只要i非j，则
        // swap
        huffman_node * t = q->nodes[i];
        q->nodes[i] = q->nodes[j];
        q->nodes[j] = t;
        i = j;
    } // 二者换位，并继续考查下降后的i
    return i; // 返回下滤抵达的位置（亦i亦j）
}

void pq_heapify(pq * q, int n) { // Floyd建堆算法，O(n)时间
    for (int i = last_internal(n); in_heap(n, i); i--) { // 自底而上，依次
        pq_percolate_down(q, n, i); // 下滤各内部节点
    }
}

void pq_insert(pq * q, huffman_node * node) { // 将词条插入完全二叉堆中
    // 首先将新词条接至向量末尾
    q->nodes[q->size] = node;
    q->size++;
    // 再对该词条实施上滤调整
    pq_percolate_up(q, q->size - 1); 
}

huffman_node * pq_delmax(pq * q) { // 删除非空完全二叉堆中优先级最高的词条
    huffman_node * max = q->nodes[0];
    q->nodes[0] = q->nodes[--(q->size)]; // 摘除堆顶（首词条），代之以末词条
    pq_percolate_down(q, q->size, 0); // 对新堆顶实施下滤
    return max; // 返回此前备份的最大词条，需要外部释放
}

pq * char_statistics(unsigned char * file_name, int * byte_count) {
    *byte_count = 0;
    // 初始化 pq
    pq * q = pq_create();
    huffman_node * nodes[256];
    for (int i = 0; i < 256; ++i) {
        nodes[i] = huffman_node_create_external_node(i);
    }
    // 从文件流中读取
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
    // 建堆
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
    unsigned char bits[256] = { 0, }; // 先序遍历
    _mapper_set_all(mappers, forest, 0, bits);
}

// ------------------------------------------------------------------------------------------

typedef struct huffman_buffer {
    int current_bit_size;
    int byte_capacity;
    unsigned char * buffer;bu
} huffman_buffer;

huffman_buffer * huffman_buffer_create(int max_byte_count) {
    huffman_buffer * buffer = (huffman_buffer *)malloc(sizeof(huffman_buffer));
    buffer->current_bit_size = 0;
    buffer->byte_capacity = max_byte_count;
    //! 初始化为0
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
    static int j = 0;
    for (int i = 0; i < bit_count; ++i) {
        if (bits[i] == 1) {
            buffer->buffer[g] |= (0x1 << (buffer->current_bit_size % 8));
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

// 传入指针指针作为返回值
int read_from_file(huffman_buffer ** info_buffer, huffman_buffer ** data_buffer, char * file_name) {
    // 从文件流中读取
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
    // 初始化 pq
    pq * q = pq_create();
    huffman_node * nodes[256];
    char * data_offset = info_buffer->buffer + 2 * sizeof(int) + 16;
    for (int i = 0; i < 256; ++i) {
        nodes[i] = huffman_node_create_external_node(i);
        nodes[i]->weight = ((int *)data_offset)[i];
    }
    // 建堆
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
    // 注意，此棵huffman树不是规整的左0右1，根节点是正常的左孩子，根节点右孩子还是正常的右孩子，其余一致
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
    return md5_code; // 需要外部释放
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

    huffman_buffer * data_buffer = huffman_buffer_create(decompressed_size * 2); // 经验值 emmmmm
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
