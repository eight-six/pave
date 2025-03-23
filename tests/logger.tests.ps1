BeforeAll {
    Import-Module "$PSScriptRoot/../modules/pave-logger" -Force
}


Describe "formatting emphasis" {
    it "wraps text in <em> tags" {
        $Actual = em 'flaming zebra'
        $Actual | Should -Be '<em>flaming zebra</em>'
    }

    it "wraps text in ems empty" {
       {em ''} | Should -Throw 
    }
}

Describe "formatting underline" {
    $Tests = @(
        @{Text = 'flaming zebra'; Expected = '<u>flamin</u>g<u> zebra</u>'}
        @{Text = 'papaya'; Expected = 'p<u>a</u>p<u>a</u>y<u>a</u>'}
        @{Text = 'birthday'; Expected = '<u>birthda</u>y'}
    )

    it "wraps text in <u> tags" -ForEach $Tests {
        $Actual = u $Text
        $Actual | Should -Be $Expected
    }

    it "throws when text is empty" {
       {u ''} | Should -Throw 
    }
}

Describe "formatting bold" {
    it "wraps text in <b> tags" {
        $Actual = b 'flaming zebra'
        $Actual | Should -Be '<b>flaming zebra</b>'
    }

    it "throws when text is empty" {
       {b ''} | Should -Throw 
    }
}