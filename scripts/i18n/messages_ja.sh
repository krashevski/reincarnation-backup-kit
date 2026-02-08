#!/bin/bash
# ====================================================================
# Reincarnation Backup Kit — MIT ライセンス
# Copyright (c) 2025 Vladislav Krashevsky
# 本ソフトウェアおよび関連ドキュメント
# ファイル（以下「本ソフトウェア」）のコピーを入手したすべての人に対し、
# いかなる制限もなく本ソフトウェアを取り扱うことを無償で許可します。これには、
# 本ソフトウェアの使用、
# 複製、変更、統合、公開、配布、サブライセンス、および/または
# 販売する権利が含まれますが、これらに限定されません。ただし、以下の条件が適用されます。
# 上記の著作権表示およびこの許可通知は、
# 本ソフトウェアのすべてのコピーまたは大部分に含まれるものとします。
# 本ソフトウェアは「現状有姿」で提供され、いかなる種類の保証もありません。
# =========================================================================
# messages_en.sh
# Reincarnation Backup Kit — メッセージライブラリ
# すべてのスクリプトで統一された英語メッセージ
# MITライセンス — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
# ======================================================================

MSG[hello]="Hello, world!"
MSG[start]="開始しています"

# 共通ライブラリ
# privileges.sh
MSG[run_sudo]="スクリプトはroot権限（sudo）で実行する必要があります"
# cleanup.sh
MSG[clean_ok]="一時ファイルを削除しました。"
MSG[clean_tmp]="一時ファイルをクリーンアップしています…"
MSG[clean_invalid_dir]="無効なディレクトリ: %s"
msg_cleanup_start="一時ファイルをクリーンアップしています"
msg_cleanup_done="クリーンアップ完了"
msg_removing="削除中"
msg_unsafe_path="安全でないパスのため、操作はキャンセルされました"
# deps.sh
MSG[deps_missing_list]="依存関係がありません: %s"
MSG[deps_install_try]="自動インストールを試行します…"
MSG[unknown_manager]="不明なパッケージマネージャーです。手動でインストールしてください: %s"
MSG[deps_missing]="パッケージがインストールされていません。インストールしてください"
MSG[deps_ok]="すべての依存関係がインストールされました"
# run-step
MSG[step_ok]="%s — 正常に完了しました"
MSG[step_fail]="%s — 失敗しました（参照%s)"
MSG[not_function]="'%s' は関数ではありません"
MSG[step_extract]="アーカイブを抽出しています"
MSG[step_repos]="リポジトリとキーリングを復元しています"
MSG[step_packages]="パッケージを復元しています"
MSG[step_logs]="ログを復元しています"
MSG[system_packages]="システムパッケージ"
MSG[archive]="アーカイブ"
MSG[backup_fail]="バックアップに失敗しました"
# init.sh
MSG[init_start]="ディレクトリを初期化しています"
MSG[dir_created]="ディレクトリを作成しました"
MSG[dir_exists]="ディレクトリが既に存在します"
MSG[dir_create_failed]="ディレクトリの作成に失敗しました"
MSG[dir_empty]="ディレクトリパスが空です"
msg_init_user_dirs="ユーザーを初期化していますディレクトリ"
msg_init_system_dirs="システムディレクトリを初期化しています"
msg_unsafe_path="安全でないパス"
msg_run_sudo="root権限が必要です (sudoで実行してください)"

# restore-ubuntu-24.04.sh
MSG[archive_not_found]="バックアップアーカイブが見つかりません: %s"
MSG[extracting]="アーカイブを抽出しています…"
MSG[extract_ok]="アーカイブの抽出に成功しました。"
MSG[extract_fail]="アーカイブの抽出に失敗しました。"
MSG[repos]="APTソースとキーリングを復元しています…"
MSG[apt_failed]="aptアップデートに失敗しました。"
MSG[repos_ok]="リポジトリとキーリングを復元しました。"
MSG[repos_fail]="アーカイブにsystem_packagesディレクトリがありません。"
MSG[packages_manual]="手動でインストールしたパッケージを復元しています…"
MSG[packages_manual_ok]="手動でインストールしたパッケージを復元しました。
MSG[packages_manual_fail]="手動でインストールしたパッケージの復元に失敗しました。
MSG[packages_full]="パッケージリスト全体を復元しています…"
MSG[packages_full_ok]="パッケージリスト全体を復元しました。
MSG[packages_full_fail]="パッケージリスト全体を復元できませんでした。
MSG[packages_skip]="パッケージの復元をスキップしています (RESTORE_PACKAGES=none)。
MSG[invalid_mode]="RESTORE_PACKAGES モードが無効です: %s"
MSG[relogs]="ログを復元しています…"
MSG[relogs_ok]="ログを復元しました。
MSG[relogs_skip]="ログの復元をスキップしています。
MSG[re_start]="システムの復元を開始しています (Ubuntu 24.04)"
MSG[re_done]="システムの復元が正常に完了しました！"
MSG[re_started]="復元を開始しました"
MSG[re_extracting]="アーカイブを抽出しています"
MSG[re_repos_keys]="リポジトリとキーリングを復元しています"
MSG[re_packages]="パッケージを復元しています"
MSG[re_logs]="ログを復元しています"
MSG[re_success]="復元が正常に完了しました"
MSG[completed]="%s が完了しました。"
MSG[failed]="失敗"
MSG[re_check]="%s に失敗しました。%s を確認してください"
MSG[re_log_file]="ログファイル: %s"

# backup-ubuntu-24.04.sh
MSG[start]="システムバックアップを開始しています (Ubuntu 24.04)"
MSG[backup_started]="バックアップを開始しました"
MSG[change_owner]="ディレクトリの所有者を変更しています"
MSG[no_dir]="ディレクトリが存在しません。マウントポイントを確認してください。"
MSG[tmp_cleaned]="一時ファイルを消去しました。"
MSG[dir_missing]="ディレクトリ \$BACKUP_DIR が見つかりません。ディスクをマウントしてください！"
MSG[backup_pkgs]="システムパッケージとリポジトリをバックアップしています…"
MSG[pkgs_done]="システムパッケージを保存しました。"
MSG[create_archive]="アーカイブを作成しています"
MSG[archive_exists]="アーカイブが既に存在します。.old に名前を変更します"
MSG[archive_done]="アーカイブを作成しました: %s"
MSG[archive_fail]="アーカイブの作成に失敗しました"
MSG[backup_sucess]="システムバックアップが正常に完了しました！"
MSG[step_ok]="ステップが完了しました。"
MSG[step_fail]="ステップはエラーで完了しました。ログを確認してください。"
MSG[log_file]="ログファイル: "
MSG[backup_finished]="バックアップが正常に完了しました"
MSG[not_function]="関数が見つかりません: %s