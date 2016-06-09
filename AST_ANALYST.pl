#! perl E:\Perl\AST_ANALYST.pl
open OUTPUT,'>',"$ARGV[0].ast";                       #输出到文件
while(<>){
    if(/\A@(\d*)/){
        $num=$1;
        %name_value=();                               #对新结点建立新的字段名-值哈希
        %suffer=();
        /\A@\d*\h*(\H*) /;                            #提取结点名
        $suffer{'@'.$num}=$1;
    }
    %name_value=(
                 (%suffer),
                 (/(\H*)\h*: (\H*)/g),                #提取字段
                 (/(op\h\d*): (\H*)/),                #提取op字段
                 (/(strg): (\H*\h*)lngt/),            #提取带空格的strg字段
                );
    %suffer=%name_value;
    while(($name,$value)=each %name_value)            #编号-结点哈希的值为字段名-值哈希
        {$num_node{$num}{$name}=$value;}
}
while(($num,$node)=each %num_node){
    while(($name,$value)=each %$node){
        if($name=~/srcp/){                            #处理含srcp字段的结点
            if($value=~/([.]cpp|[.]c)/){              #保存有用结编号
                $useful_node{$num}=$num;
                delete $num_node{$num}{'srcp'};
            }
            else{                                     #记录并删除无用结点
                push @useless_node,$num;
                delete $num_node{$num};
                last;
            }
        }
    }
}
while($num1!=$num2||$num1==undef){                    #记录有用结点
    $num1=(keys %useful_node);
    foreach $a (keys %useful_node){
        foreach $b (values %{$num_node{$a}}){
            $b=~/@(\d*)/;
            if($1 && exists $num_node{$1})
                {$useful_node{$1}=$1;}
        }
    }
    $num2=(keys %useful_node);
}
while(($num,$node)=each %num_node){
    delete $num_node{$num}{'algn'};                   #删除algn字段
    delete $num_node{$num}{'lngt'};                   #删除lngt字段
    %r_node=reverse %$node;
    if(exists $r_node{'scope_stmt'}){                 #处理scope_stmt结点
        foreach $key (keys %$node){
            if($key ne 'end' && $key ne 'begin' && $key ne 'line' && $key ne 'next' && $key!~/@\d*/)
                {delete $num_node{$num}{$key};}
        }
    }
    if(exists $r_node{'integer_type'})                #处理简单类型结点
        {%{$num_node{$num}}=('@'.$num => 'integer_type');}
    if(exists $r_node{'real_type'})
        {%{$num_node{$num}}=('@'.$num => 'real_type');}
    if(exists $r_node{'void_type'})
        {%{$num_node{$num}}=('@'.$num => 'void_type');}
    if(exists $r_node{'record_type'})
        {%{$num_node{$num}}=('@'.$num => 'record_type');}
    if(exists $r_node{'union_type'})
        {%{$num_node{$num}}=('@'.$num => 'union_type');}
    if(exists $r_node{'enumeral_type'})
        {%{$num_node{$num}}=('@'.$num => 'enumeral_type');}
    unless(exists $useful_node{$num})
        {delete $num_node{$num};}                     #删除无用结点
}
while(($num,$node)=each %num_node){
    %r_node=reverse %$node;
    foreach $key (keys %r_node){                      #删除值为无用结点的字段
        if($key=~/@(\d*)/){
            unless(exists $useful_node{$1})
                {delete $num_node{$num}{$r_node{$key}};}
        }
    }
}
$new_num=1;                                           #编号映射
foreach $1 (keys %useful_node){
    $old_new{$1}=$new_num;
    $new_num++;
}
while(($old,$new)=each %old_new){
    while(($num,$node)=each %num_node){
        while(($name,$value)= each %$node){
            if($name=~s/@($old)/\@$new/||$value=~s/@($old)/\@$new/)
                {$num_node_new{$old_new{$num}}{$name}=$value;}
            if($name!~s/@($old)/\@$new/&&$value!~s/@($old)/\@$new/&&$name!~/@/&&$value!~/@/)
                {$num_node_new{$old_new{$num}}{$name}=$value;}
        }
    }
}
%num_node=();
while(($num,$node)=each %num_node_new){
    while(($name,$value)=each %$node)
        {print OUTPUT "$name: $value ";}
    print OUTPUT "\n";
}
close OUTPUT;
