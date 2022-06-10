﻿###################################################################################
#  TVerRec : TVerビデオダウンローダ
#
#		無視対象ビデオ削除処理スクリプト
#
#	Copyright (c) 2022 dongaba
#
#	Licensed under the MIT License;
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in
#	all copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#	THE SOFTWARE.
#
###################################################################################

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#環境設定
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Set-StrictMode -Version Latest
try {
	if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
		$script:scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
		$script:scriptName = Split-Path -Leaf -Path $MyInvocation.MyCommand.Definition
	}
 else {
		$script:scriptRoot = Convert-Path .
	}
	Set-Location $script:scriptRoot
	$script:confDir = $(Convert-Path $(Join-Path $script:scriptRoot '..\conf'))
	$script:devDir = $(Join-Path $script:scriptRoot '..\dev')

	#----------------------------------------------------------------------
	#外部設定ファイル読み込み
	$script:sysFile = $(Convert-Path $(Join-Path $script:confDir 'system_setting.ps1'))
	$script:confFile = $(Convert-Path $(Join-Path $script:confDir 'user_setting.ps1'))
	. $script:sysFile
	. $script:confFile

	#----------------------------------------------------------------------
	#外部関数ファイルの読み込み
	. $(Convert-Path (Join-Path $script:scriptRoot '.\functions\common_functions.ps1'))
	. $(Convert-Path (Join-Path $script:scriptRoot '.\functions\tver_functions.ps1'))

	#----------------------------------------------------------------------
	#開発環境用に設定上書き
	if ($PSVersionTable.PSEdition -eq 'Desktop') {
		$script:devFunctionFile = $(Join-Path $script:devDir 'dev_funcitons.ps1')
		$script:devConfFile = $(Join-Path $script:devDir 'dev_setting.ps1')
		if (Test-Path $script:devFunctionFile) {
			. $script:devFunctionFile
			Write-ColorOutput '　開発ファイル用共通関数ファイルを読み込みました' white DarkGreen
		}
		if (Test-Path $script:devConfFile) {
			. $script:devConfFile
			Write-ColorOutput '　開発ファイル用設定ファイルを読み込みました' white DarkGreen
		}
	}
 else {
		$script:devFunctionFile = $(Join-Path $script:devDir 'dev_funcitons.ps1')
		$script:devConfFile = $(Join-Path $script:devDir 'dev_setting.ps1')
		if (Test-Path $script:devFunctionFile) {
			. $script:devFunctionFile
			Write-ColorOutput '　開発ファイル用共通関数ファイルを読み込みました' white DarkGreen
		}
		if (Test-Path $script:devConfFile) {
			. $script:devConfFile
			Write-ColorOutput '　開発ファイル用設定ファイルを読み込みました' white DarkGreen
		}
	}
}
catch { Write-Error '設定ファイルの読み込みに失敗しました' ; exit 1 }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理

#======================================================================
#半日以上前のログファイル・ロックファイルを削除
try {
	$script:ffmpegErrorLogDir = Split-Path $script:ffpmegErrorLogPath
	Get-ChildItem -Path $script:ffmpegErrorLogDir -Recurse -Filter 'ffmpeg_error_*.log' `
	| Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-0.5) } `
	| Remove-Item -Force -ErrorAction SilentlyContinue
}
catch { Write-ColorOutput 'ffmpegエラーファイルを削除できませんでした' Green }
try {
	Get-ChildItem -Path $scriptRoot -Recurse -Filter 'brightcovenew_*.lock' `
	| Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-0.5) } `
	| Remove-Item -Force -ErrorAction SilentlyContinue
}
catch { Write-ColorOutput 'youtube-dlのロックファイルを削除できませんでした' Green }

#======================================================================
#1/3 ダウンロードが中断した際にできたゴミファイルは削除
Write-ColorOutput '----------------------------------------------------------------------'
Write-ColorOutput 'ダウンロードが中断した際にできたゴミファイルを削除します'
Write-ColorOutput '----------------------------------------------------------------------'
#進捗表示
Write-Progress -Id 1 `
	-Activity '処理 1/3' `
	-PercentComplete $($( 1 / 3 ) * 100) `
	-Status 'ゴミファイルを削除'
ShowProgressToast 'ファイルの掃除中' '　処理1/3 - ダウンロード中断時のゴミファイルを削除' '' "$($script:appName)" 'Delete' 'long' $false
Write-Progress -Id 2 -ParentId 1 `
	-Activity '1/3' `
	-PercentComplete $($( 1 / 3 ) * 100) `
	-Status $script:downloadBaseDir
UpdateProgessToast "$($script:downloadWorkDir)" "$($( 1 / 3 ))" '' '' `
	"$($script:appName)" 'Delete'

#処理
deleteTrashFiles $script:downloadWorkDir '*.ytdl, *.jpg, *.vtt, *.temp.mp4, *.part, *.mp4.part-Frag*, *.mp4'

#進捗表示
Write-Progress -Id 2 -ParentId 1 `
	-Activity '2/3' `
	-PercentComplete $($( 2 / 3 ) * 100) `
	-Status $script:downloadWorkDir
UpdateProgessToast "$($script:downloadBaseDir)" "$($( 2 / 3 ))" '' '' `
	"$($script:appName)" 'Delete'

#処理
deleteTrashFiles $script:downloadBaseDir '*.ytdl, *.jpg, *.vtt, *.temp.mp4, *.part, *.mp4.part-Frag*'

#進捗表示
Write-Progress -Id 2 -ParentId 1 `
	-Activity '3/3' `
	-PercentComplete $($( 3 / 3 ) * 100) `
	-Status $script:saveBaseDir
UpdateProgessToast "$($script:saveBaseDir)" "$($( 3 / 3 ))" '' '' `
	"$($script:appName)" 'Delete'

#処理
deleteTrashFiles $script:saveBaseDir '*.ytdl, *.jpg, *.vtt, *.temp.mp4, *.part, *.mp4.part-Frag*'

#======================================================================
#2/3 無視リストに入っている番組は削除
Write-ColorOutput '----------------------------------------------------------------------'
Write-ColorOutput '削除対象のビデオを削除します'
Write-ColorOutput '----------------------------------------------------------------------'
#進捗表示
Write-Progress -Id 1 `
	-Activity '処理 2/3' `
	-PercentComplete $($( 2 / 3 ) * 100) `
	-Status '削除対象のビデオを削除'
ShowProgressToast 'ファイルの掃除中' '　処理2/3 - 削除対象のビデオを削除' '' `
	"$($script:appName)" 'Delete' 'long' $false

#ダウンロード対象外ビデオ番組リストの読み込み
$local:ignoreTitles = (Get-Content $script:ignoreFilePath -Encoding UTF8 `
	| Where-Object { !($_ -match '^\s*$') } `
	| Where-Object { !($_ -match '^;.*$') }) `
	-as [string[]]

#処理
$local:ignoreNum = 0						#無視リスト内の番号
if ($local:ignoreTitles -is [array]) {
	$local:ignoreTotal = $local:ignoreTitles.Length	#無視リスト内のエントリ合計数
}
else { $local:ignoreTotal = 1 }

#----------------------------------------------------------------------
$local:totalStartTime = Get-Date
foreach ($local:ignoreTitle in $local:ignoreTitles) {
	#処理時間の推計
	$local:secElapsed = (Get-Date) - $local:totalStartTime
	$local:secRemaining = -1
	if ($local:ignoreNum -ne 0) {
		$local:secRemaining = ($local:secElapsed.TotalSeconds / $local:ignoreNum) * ($local:ignoreTotal - $local:ignoreNum)
		$local:minRemaining = "$([String]([math]::Ceiling($local:secRemaining / 60)))分"
		$local:progressRatio = $($local:ignoreNum / $local:ignoreTotal)
	}
 else {
		$local:minRemaining = '計算中...'
		$local:progressRatio = 0
	}
	$local:ignoreNum = $local:ignoreNum + 1

	#進捗表示
	Write-Progress -Id 2 -ParentId 1 `
		-Activity "$($local:ignoreNum)/$($local:ignoreTotal)" `
		-PercentComplete $($local:progressRatio * 100) `
		-Status $local:ignoreTitle
	UpdateProgessToast "$($local:ignoreTitle)" "$($local:progressRatio)" `
		"$($local:ignoreNum)/$($local:ignoreTotal)" "残り時間 $local:minRemaining" `
		"$($script:appName)" 'Delete'

	#処理
	Write-ColorOutput '----------------------------------------------------------------------'
	Write-ColorOutput "$($local:ignoreTitle)を処理中"
	try {
		$local:delTargets = Get-ChildItem -LiteralPath $script:downloadBaseDir `
			-Directory -Name -Filter "*$($local:ignoreTitle)*"
	}
 catch { Write-ColorOutput '削除対象を特定できませんでした' Green }
	try {
		if ($null -ne $local:delTargets) {
			foreach ($local:delTarget in $local:delTargets) {
				if (Test-Path $(Join-Path $script:downloadBaseDir $local:delTarget) -PathType Container) {
					Write-ColorOutput "  └「$(Join-Path $script:downloadBaseDir $local:delTarget)」を削除します"
					Remove-Item -Path $(Join-Path $script:downloadBaseDir $local:delTarget) `
						-Recurse -Force -ErrorAction SilentlyContinue
				}
			}
		}
		else { Write-ColorOutput '　削除対象はありませんでした' DarkGray }
	}
 catch { Write-ColorOutput '削除できないファイルがありました' Green }
}
#----------------------------------------------------------------------

#======================================================================
#3/3 空フォルダと隠しファイルしか入っていないフォルダを一気に削除
Write-ColorOutput '----------------------------------------------------------------------'
Write-ColorOutput '空フォルダを削除します'
Write-ColorOutput '----------------------------------------------------------------------'
#進捗表示
Write-Progress -Id 1 -Activity '処理 3/3' `
	-PercentComplete $($( 3 / 3 ) * 100) `
	-Status '空フォルダを削除'
ShowProgressToast 'ファイルの掃除中' '　処理3/3 - 空フォルダを削除' '' "$($script:appName)" 'Delete' 'long' $false

#処理
$local:allSubDirs = @((Get-ChildItem -LiteralPath $script:downloadBaseDir -Recurse).Where({ $_.PSIsContainer })).FullName `
| Sort-Object -Descending

$local:subDirNum = 0						#サブディレクトリの番号
if ($local:allSubDirs -is [array]) {
	$local:subDirTotal = $local:allSubDirs.Length	#サブディレクトリの合計数
}
else { $local:subDirTotal = 1 }

#----------------------------------------------------------------------
$local:totalStartTime = Get-Date
foreach ($local:subDir in $local:allSubDirs) {
	#処理時間の推計
	$local:secElapsed = (Get-Date) - $local:totalStartTime
	$local:secRemaining = -1
	if ($local:subDirNum -ne 0) {
		$local:secRemaining = ($local:secElapsed.TotalSeconds / $local:subDirNum) * ($local:subDirTotal - $local:subDirNum)
		$local:minRemaining = "$([String]([math]::Ceiling($local:secRemaining / 60)))分"
		$local:progressRatio = $($local:subDirNum / $local:subDirTotal)
	}
 else {
		$local:minRemaining = '計算中...'
		$local:progressRatio = 0
	}
	$local:subDirNum = $local:subDirNum + 1

	#進捗表示
	Write-Progress -Id 2 -ParentId 1 `
		-Activity "$($local:subDirNum)/$($local:subDirTotal)" `
		-PercentComplete $($local:progressRatio * 100) `
		-Status $local:subDir
	UpdateProgessToast "$($local:subDir)" "$($local:progressRatio)" `
		"$($local:subDirNum)/$($local:subDirTotal)" "残り時間 $local:minRemaining" `
		"$($script:appName)" 'Delete'

	#処理
	Write-ColorOutput '----------------------------------------------------------------------'
	Write-ColorOutput "$($local:subDir)を処理中"
	if (@((Get-ChildItem -LiteralPath $local:subDir -Recurse).Where({ ! $_.PSIsContainer })).Count -eq 0) {
		try {
			Write-ColorOutput "  └「$($local:subDir)」を削除します"
			Remove-Item -LiteralPath $local:subDir `
				-Recurse -Force -ErrorAction SilentlyContinue
		}
		catch { Write-ColorOutput "空フォルダの削除に失敗しました: $local:subDir" Green }
	}
}
#----------------------------------------------------------------------

#進捗表示
UpdateProgessToast 'ファイルの掃除' '1' '' '完了' "$($script:appName)" 'Delete'

