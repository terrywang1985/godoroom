#!/usr/bin/env python3
"""
PNG位深度转换脚本
将目录中的所有PNG图片转换为32位深度（带Alpha通道）
"""

import os
import sys
from PIL import Image
import argparse

def convert_png_to_32bit(input_path, output_path=None, backup=True):
    """
    将PNG图片转换为32位深度
    
    Args:
        input_path: 输入图片路径
        output_path: 输出图片路径（如果为None则覆盖原文件）
        backup: 是否创建备份
    """
    try:
        # 打开图片
        with Image.open(input_path) as img:
            # 检查图片模式
            if img.mode == 'RGBA':
                print(f"✓ {input_path} 已经是32位RGBA格式")
                return True
                
            # 转换为RGBA模式（32位）
            if img.mode == 'RGB':
                # RGB转RGBA，添加不透明的Alpha通道
                rgba_img = img.convert('RGBA')
            else:
                # 其他模式（如P、L等）先转RGB再转RGBA
                rgb_img = img.convert('RGB')
                rgba_img = rgb_img.convert('RGBA')
            
            # 处理输出路径
            if output_path is None:
                if backup:
                    # 创建备份文件
                    base, ext = os.path.splitext(input_path)
                    backup_path = f"{base}_backup{ext}"
                    os.rename(input_path, backup_path)
                    print(f"✓ 已创建备份: {backup_path}")
                output_path = input_path
            
            # 保存为32位PNG
            rgba_img.save(output_path, 'PNG')
            print(f"✓ 转换成功: {input_path} -> {output_path} (32位RGBA)")
            return True
            
    except Exception as e:
        print(f"✗ 处理失败 {input_path}: {str(e)}")
        return False

def process_directory(directory, recursive=True, backup=True):
    """
    处理目录中的所有PNG文件
    
    Args:
        directory: 要处理的目录
        recursive: 是否递归处理子目录
        backup: 是否创建备份
    """
    converted_count = 0
    error_count = 0
    
    print(f"开始处理目录: {directory}")
    print("-" * 50)
    
    # 遍历目录
    for root, dirs, files in os.walk(directory if recursive else [directory]):
        for file in files:
            if file.lower().endswith('.png'):
                file_path = os.path.join(root, file)
                
                if convert_png_to_32bit(file_path, backup=backup):
                    converted_count += 1
                else:
                    error_count += 1
    
    print("-" * 50)
    print(f"处理完成!")
    print(f"成功转换: {converted_count} 个文件")
    print(f"处理失败: {error_count} 个文件")

def main():
    parser = argparse.ArgumentParser(description='将PNG图片转换为32位深度')
    parser.add_argument('directory', nargs='?', default='.', 
                       help='要处理的目录（默认为当前目录）')
    parser.add_argument('--no-recursive', action='store_true',
                       help='不递归处理子目录')
    parser.add_argument('--no-backup', action='store_true',
                       help='不创建备份文件')
    parser.add_argument('--output', '-o', 
                       help='输出目录（如果不指定则覆盖原文件）')
    
    args = parser.parse_args()
    
    # 检查目录是否存在
    if not os.path.exists(args.directory):
        print(f"错误: 目录 '{args.directory}' 不存在")
        sys.exit(1)
    
    # 检查PIL是否可用
    try:
        from PIL import Image
    except ImportError:
        print("错误: 需要安装PIL库，请运行: pip install Pillow")
        sys.exit(1)
    
    # 处理目录
    process_directory(
        directory=args.directory,
        recursive=not args.no_recursive,
        backup=not args.no_backup
    )

if __name__ == "__main__":
    main()