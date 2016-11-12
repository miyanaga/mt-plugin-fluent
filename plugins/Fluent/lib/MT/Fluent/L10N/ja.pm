package MT::Fluent::L10N::ja;

use strict;
use utf8;
use base 'MT::Fluent::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
    'Plugin to log activities in Movable Type to Fluentd.' => 'Movable Type上でのさまざまな動きをFluentdにログ出力するプラグインです。',
    'Entry And Page JSON Log For Fluentd' => 'Fluentd用の記事とウェブページのJSONログ',

    'Fluentd Server' => 'Fluentdサーバ',
    'Hostname' => 'ホスト名',
    'Port' => 'ポート番号',
    'This hostname' => 'このホスト名',
    'The original hostname:' => '推定されるホスト名:',
    'Hostname to merge to Fluent message. Blank to send nothing.' => '送信するFluentメッセージにマージするホスト名を指定してください。空欄の場合はホス名を自動で送信しません。',

    'Log' => 'ログ',
    'Log Tag' => 'ログのタグ',
    'Send Movable Type logs to fluentd.' => 'Movable Typeのログをfluentdに送信します。',
    'Usage' => '利用状況',
    'Usage Tag' => '利用状況タグ',
    'Send to fluentd log who used and how did it.' => '誰がどのような操作を行ったかのログをFluentdに送信します。',
    'Error' => '発生エラー',
    'Error Tag' => '発生エラータグ',
    'Send errors on Movable Type to fluentd.' => 'このMovable Typeで発生したエラーをFluentdに送信します。',
    'Performance' => 'パフォーマンス',
    'Performance Tag' => 'パフォーマンスタグ',
    'Send performance time such as rebuilding to fluentd.' => '再構築の時間などのパフォーマンスデータをFluentdに送信します。',
    'Choose tag to log this event.' => 'このイベントに付加するタグを指定してください。',

    'Logging changes' => '変更をログに出力する',
    'Entry' => '記事',
    'Entry Tag' => '記事のタグ',
    'Entry Template' => '記事のテンプレート',
    'Choose a template to build entry log JSON.' => '記事のログJSONデータを構築するためのテンプレートを選択してください。',
    'Page' => 'ウェブページ',
    'Page Tag' => 'ウェブページのタグ',
    'Page Template' => 'ウェブページのテンプレート',
    'Choose a template to build page log JSON.' => 'ウェブページのログJSONデータを構築するためのテンプレートを選択してください。',

    'Error in Fluent message template compile: [_1]' => 'Fluentメッセージテンプレートのコンパイルでエラーが発生しました: [_1]',
    'Error in Fluent message building: [_1]' => 'Fluentメッセージテンプレートの構築でエラーが発生しました: [_1]',
    'Error to parse Fluent message JSON.' => 'FluentメッセージをJSONとして解析することができません。',
);

1;
