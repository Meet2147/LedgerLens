package com.dashovia.ledgerlens.mobile

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.dashovia.ledgerlens.mobile.ui.LedgerLensMobileApp
import com.dashovia.ledgerlens.mobile.ui.theme.LedgerLensTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            LedgerLensTheme {
                LedgerLensMobileApp()
            }
        }
    }
}
