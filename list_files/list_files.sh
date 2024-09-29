#!/bin/bash

# デフォルト値
OUTPUT_FILE=""
CUSTOM_MESSAGE="以下はディレクトリ構造とファイル内容です。レビューしてください。"

# オプション
while getopts ":o:m:" opt; do
  case ${opt} in
    o )
      OUTPUT_FILE=$OPTARG
      ;;
    m )
      CUSTOM_MESSAGE=$OPTARG
      ;;
    \? )
      echo "使用法: $0 [-o output_file] [-m custom_message] /path/to/directory"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# 引数
TARGET_DIR="${1:-.}"

if [ "$TARGET_DIR" = "." ]; then
    DIR_NAME=$(basename "$PWD")
else
    DIR_NAME=$(basename "$TARGET_DIR")
fi

if [ ! -d "$TARGET_DIR" ];then
    echo "エラー: '$TARGET_DIR' はディレクトリではないか、存在しません。"
    exit 1
fi

# 一時ファイルを作成
TMP_FILE=$(mktemp)

# .gitignoreのパターンを取得
if [ -f .gitignore ]; then
    IGNORE_PATTERN=$(echo -n ".git|" && grep -v '^#' .gitignore | sed 's|^/||' | paste -sd "|")
else
    IGNORE_PATTERN=$(echo ".git")
fi
echo "gitignoreのパターン: $IGNORE_PATTERN"


# ディレクトリ構造を表示
{
    echo "$CUSTOM_MESSAGE"
    echo
    echo "## ディレクトリ構造"
    echo
    echo '```'
    if command -v tree >/dev/null 2>&1; then
        tree "$TARGET_DIR" -a -I "$IGNORE_PATTERN"
    else
        echo "treeコマンドが見つからないため、findコマンドを使用します。" >&2
        find "$TARGET_DIR" -print | sed "s|^\.|$DIR_NAME|"
    fi
    echo '```'
    echo
} >> "$TMP_FILE" || { echo "エラー: '$TMP_FILE' への書き込みに失敗しました。"; exit 1; }

print_file_contents() {
    local file="$1"
    # . を DIR_NAME に置き換えて表示する
    local display_file=$(echo "$file" | sed "s|^\./|$DIR_NAME/|")
    {
        echo "## $display_file"
        echo
        echo '```'
        if ! cat "$file" 2>/dev/null; then
            echo "エラー: $file の読み取りに失敗しました。"
        fi
        echo '```'
        echo
    } >> "$TMP_FILE" || { echo "エラー: '$TMP_FILE' への書き込みに失敗しました。"; exit 1; }
}

# find コマンドで表示されたファイル内容を表示
find "$TARGET_DIR" -type d -name '.git' -prune -o -type f | while IFS= read -r file; do
    # ファイルが .gitignore にマッチしない場合
    if ! git check-ignore -q "$file"; then
        # バイナリファイルをスキップ
        if file "$file" | grep -q 'text'; then
            print_file_contents "$file"
        fi
    fi
done

# アウトプット処理
if [ -n "$OUTPUT_FILE" ]; then
    mv "$TMP_FILE" "$OUTPUT_FILE" && rm "$TMP_FILE"
    echo "'$OUTPUT_FILE' に結果を保存しました。"
else
    if command -v pbcopy >/dev/null 2>&1; then
        cat "$TMP_FILE" | pbcopy
        echo "結果をクリップボードにコピーしました。"
    elif command -v xclip >/dev/null 2>&1; then
        cat "$TMP_FILE" | xclip -selection clipboard
        echo "結果をクリップボードにコピーしました。"
    else
        echo "エラー: pbcopy または xclip が見つかりません。結果を表示します:"
        cat "$TMP_FILE"
    fi
    rm "$TMP_FILE"
fi
