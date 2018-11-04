# 说明

## 内容

src文件夹中的文件为项目包含的所有*.inc与*.asm文件。
vs2017_sln文件夹为项目的vs2017解决方案，打开后稍微配置即可汇编运行本项目。



## 汇编方法
本项目使用到了msvcrt.lib，即微软VC运行时库，最好构建VS Studio解决方案，一键汇编生成。
可以使用vs2017_sln文件夹中提供的vs2017解决方案。流程如下：

1. 打开Compressor-Decompressor.sln后，打开Compressor-Decompressor-Asm属性页。
2. 链接器 -> 常规 -> 附加库目录 中增加本地masm32的lib文件夹。
    如masm32安装位置为 C:\masm32，那么此项目应修改为 C:\masm32\lib;
3. Microsoft Macro Assembler -> Include Paths 中增加本地masm32的include文件夹。
    如masm32安装位置为  C:\masm32，那么此项目应修改为 C:\masm32\include;
4. 汇编运行。
